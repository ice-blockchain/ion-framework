// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/user/model/user_relays.f.dart';
import 'package:ion/app/features/user/providers/current_user_identity_provider.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_relays_ranker.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/pauseable_periodic_runner/pauseable_periodic_runner.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ranked_user_relays_provider.r.g.dart';

/// Ranked relays are the relays that are sorted based on their latency.
///
/// Latency is measured by pinging the relays (check [ionConnectRelaysRankerProvider] for details).
/// Emits the ranked relays every time a relay ping is completed.
/// That is done to avoid hanging the app while waiting for unreachable relays to respond.
@Riverpod(keepAlive: true)
class RankedCurrentUserRelays extends _$RankedCurrentUserRelays {
  @override
  Stream<List<UserRelay>> build() async* {
    final currentUserRelays = await ref.watch(currentUserIdentityConnectRelaysProvider.future);

    if (currentUserRelays == null) {
      yield [];
      return;
    }

    final pingIntervalSeconds =
        ref.watch(envProvider.notifier).get<int>(EnvVariable.RELAY_PING_INTERVAL_SECONDS);

    final controller = StreamController<List<UserRelay>>();
    ref
        .watch(
          pauseablePeriodicRunnerProvider('rankedCurrentUserRelays'),
        )
        .start(
          interval: Duration(seconds: pingIntervalSeconds),
          onTick: (cancelToken) =>
              controller.addStream(_rank(currentUserRelays, cancelToken: cancelToken)),
          runImmediately: true,
        );

    ref.onDispose(() async {
      await controller.close();
    });

    yield* controller.stream;
  }

  void reportUnreachableRelay(String relayUrl) {
    Logger.log('[RELAY] Reporting unreachable relay: $relayUrl');
    final updatedRelays = state.valueOrNull?.where((relay) => relay.url != relayUrl).toList() ?? [];
    state = AsyncValue.data(updatedRelays);
  }

  Stream<List<UserRelay>> _rank(
    List<UserRelay> relays, {
    required CancelToken cancelToken,
  }) async* {
    if (relays.isEmpty) {
      yield [];
      return;
    }

    final relaysUrls = relays.map((relay) => relay.url).toList();

    Logger.log('[RELAY] Start ranking relays: $relaysUrls');

    final rankedResultsStream =
        ref.read(ionConnectRelaysRankerProvider).ranked(relaysUrls, cancelToken: cancelToken);

    var rankedRelays = <UserRelay>[];
    await for (final results in rankedResultsStream) {
      rankedRelays = results
          .where((rankedRelay) => rankedRelay.isReachable)
          .map((rankedRelay) => relays.firstWhereOrNull((relay) => relay.url == rankedRelay.url))
          .nonNulls
          .toList();
      if (rankedRelays.isNotEmpty) {
        yield rankedRelays;
      }
    }

    // forcefully yield the final ranked relays in case nothing was
    // yielded during the stream to avoid listeners hanging
    if (rankedRelays.isEmpty) {
      yield rankedRelays;
    }
    Logger.log('[RELAY] Ranked relays: $rankedRelays');
  }
}
