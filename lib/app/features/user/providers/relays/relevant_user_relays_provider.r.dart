// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/user/providers/relays/ranked_user_relays_provider.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_relays_ranker.r.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion/app/services/pauseable_periodic_runner/pauseable_periodic_runner.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'relevant_user_relays_provider.r.g.dart';

/// Relevant relays are the ones that might be used by a user.
///
/// They are fetched from identity based on the top relay URL from the ranked user relays.

@Riverpod(keepAlive: true)
Future<List<String>> relevantCurrentUserRelays(Ref ref) async {
  final topRelayUrl = await ref.watch(
    rankedCurrentUserRelaysProvider.selectAsync((state) => state.firstOrNull?.url),
  );
  if (topRelayUrl == null) {
    return [];
  }
  return ref.watch(relevantRelaysProvider(topRelayUrl).future);
}

@riverpod
Future<List<String>> relevantRelays(Ref ref, String relayUrl) async {
  final client = await ref.watch(ionIdentityClientProvider.future);
  final availableRelays = await client.users.availableIonConnectRelays(relayUrl: relayUrl);
  return availableRelays.map((relay) => relay.url).toList();
}

@Riverpod(keepAlive: true)
class RankedRelevantCurrentUserRelaysUrls extends _$RankedRelevantCurrentUserRelaysUrls {
  @override
  Stream<List<String>> build() async* {
    final relevantRelaysUrls = await ref.watch(relevantCurrentUserRelaysProvider.future);

    final pingIntervalSeconds =
        ref.watch(envProvider.notifier).get<int>(EnvVariable.RELAY_PING_INTERVAL_SECONDS);

    final controller = StreamController<List<String>>();
    ref
        .watch(
          pauseablePeriodicRunnerProvider('rankedRelevantCurrentUserRelays'),
        )
        .start(
          interval: Duration(seconds: pingIntervalSeconds),
          onTick: (cancelToken) =>
              controller.addStream(_rank(relevantRelaysUrls, cancelToken: cancelToken)),
          runImmediately: true,
        );

    ref.onDispose(() async {
      await controller.close();
    });

    yield* controller.stream;
  }

  Stream<List<String>> _rank(
    List<String> relayUrls, {
    required CancelToken cancelToken,
  }) async* {
    final relaysStream = ref.read(ionConnectRelaysRankerProvider).ranked(
          relayUrls,
          cancelToken: cancelToken,
        );

    var rankedRelaysUrls = <String>[];
    await for (final results in relaysStream) {
      rankedRelaysUrls = results
          .where((rankedRelay) => rankedRelay.isReachable)
          .map((rankedRelay) => rankedRelay.url)
          .toList();
      if (rankedRelaysUrls.isNotEmpty) {
        yield rankedRelaysUrls;
      }
    }

    // forcefully yield the final ranked relays in case nothing was
    // yielded during the stream to avoid listeners hanging
    if (rankedRelaysUrls.isEmpty) {
      yield rankedRelaysUrls;
    }
  }
}
