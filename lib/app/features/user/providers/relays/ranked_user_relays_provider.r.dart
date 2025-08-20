// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/user/model/user_relays.f.dart';
import 'package:ion/app/features/user/providers/current_user_identity_provider.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_relays_ranker.r.dart';
import 'package:ion/app/services/logger/logger.dart';
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

    var cancelToken = CancelToken();

    yield* _rank(currentUserRelays, cancelToken: cancelToken);

    final pingIntervalSeconds =
        ref.watch(envProvider.notifier).get<int>(EnvVariable.RELAY_PING_INTERVAL_SECONDS);

    final controller = StreamController<List<UserRelay>>();

    final interval = Duration(seconds: pingIntervalSeconds);
    const minResumeDelay = Duration(seconds: 30);

    Timer? periodicTimer;
    Timer? nextTickTimer;
    DateTime? nextFireAt;
    Duration? remainingUntilNext;

    void fire() {
      controller.addStream(_rank(currentUserRelays, cancelToken: cancelToken));
    }

    void schedulePeriodic() {
      nextTickTimer?.cancel();
      periodicTimer?.cancel();
      periodicTimer = Timer.periodic(interval, (_) {
        nextFireAt = DateTime.now().add(interval);
        fire();
      });
      nextFireAt = DateTime.now().add(interval);
    }

    void scheduleOneShot(Duration delay) {
      periodicTimer?.cancel();
      periodicTimer = null;
      nextTickTimer?.cancel();
      nextTickTimer = Timer(delay, () {
        fire();
        schedulePeriodic();
      });
      nextFireAt = DateTime.now().add(delay);
    }

    schedulePeriodic();

    // Pause/resume behavior:
    // - When backgrounded: capture "remainingUntilNext" and stop timers; cancel in-flight ranking.
    // - When resumed: schedule a one-shot for max(remainingUntilNext, 30s), then return to periodic cadence.
    ref
      ..listen<AppLifecycleState>(appLifecycleProvider, (previous, next) {
        if (next == AppLifecycleState.resumed) {
          // Resume after max(remaining, 30s)
          cancelToken.cancel();
          cancelToken = CancelToken();
          var delay = remainingUntilNext ?? interval;
          if (delay < minResumeDelay) {
            delay = minResumeDelay;
          }
          remainingUntilNext = null;
          scheduleOneShot(delay);
        } else {
          // Background/inactive: capture remaining time and stop timers; cancel in-flight ranking
          final now = DateTime.now();
          if (nextFireAt != null) {
            var remaining = nextFireAt!.difference(now);
            if (remaining.isNegative) remaining = Duration.zero;
            remainingUntilNext = remaining;
          } else {
            remainingUntilNext = interval;
          }
          periodicTimer?.cancel();
          nextTickTimer?.cancel();
          cancelToken.cancel();
          cancelToken = CancelToken();
        }
      })
      ..onDispose(() async {
        periodicTimer?.cancel();
        nextTickTimer?.cancel();
        cancelToken.cancel();
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
