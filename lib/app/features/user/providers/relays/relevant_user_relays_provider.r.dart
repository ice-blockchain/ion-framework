// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/user/providers/relays/ranked_user_relays_provider.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_relays_ranker.r.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion/app/services/pauseable_periodic_runner/pauseable_periodic_runner.r.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
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
  static const _cacheKey = '_RankedRelevantCurrentUserRelaysCache';
  static const _cacheCreatedAtKey = '_RankedRelevantCurrentUserRelaysCacheCreatedAt';

  @override
  Stream<List<String>> build() async* {
    // If cache is available, always yield it first to speed up the feed loading, even tho it is expired
    final cached = _loadSavedState();
    if (cached != null) {
      yield cached;
    }

    final pingIntervalDuration =
        ref.watch(envProvider.notifier).get<Duration>(EnvVariable.RELAY_PING_INTERVAL_DURATION);

    final runImmediately = !_isCacheValid(cacheValidityDuration: pingIntervalDuration);

    final controller = StreamController<List<String>>();
    ref
        .watch(
          pauseablePeriodicRunnerProvider('rankedRelevantCurrentUserRelays'),
        )
        .start(
          interval: pingIntervalDuration,
          onTick: (cancelToken) => ref.read(relevantCurrentUserRelaysProvider.future).then(
                (relevantRelaysUrls) =>
                    controller.addStream(_rank(relevantRelaysUrls, cancelToken: cancelToken)),
              ),
          runImmediately: runImmediately,
        );

    ref.onDispose(() async {
      await controller.close();
    });

    listenSelf((_, next) => _saveState(next.valueOrNull));

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

  void _saveState(List<String>? state) {
    if (state != null) {
      ref.read(localStorageProvider)
        ..setStringList(_cacheKey, state)
        ..setInt(_cacheCreatedAtKey, DateTime.now().millisecondsSinceEpoch);
    }
  }

  List<String>? _loadSavedState() {
    return ref.read(localStorageProvider).getStringList(_cacheKey);
  }

  bool _isCacheValid({required Duration cacheValidityDuration}) {
    final createdAt = ref.read(localStorageProvider).getInt(_cacheCreatedAtKey);
    if (createdAt == null) return false;
    return DateTime.now().millisecondsSinceEpoch - createdAt < cacheValidityDuration.inMilliseconds;
  }
}
