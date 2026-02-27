// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/providers/event_backfill_service.r.dart';
import 'package:ion/app/features/user/providers/relays/optimal_user_relays_provider.r.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'batched_sync_service_provider.r.g.dart';

class BatchedSyncService {
  BatchedSyncService({
    required OptimalUserRelaysService optimalUserRelaysService,
    required EventBackfillService eventBackfillService,
    required int baseBatchThreshold,
  })  : _optimalUserRelaysService = optimalUserRelaysService,
        _eventBackfillService = eventBackfillService,
        _baseBatchThreshold = baseBatchThreshold;

  final OptimalUserRelaysService _optimalUserRelaysService;
  final EventBackfillService _eventBackfillService;
  final int _baseBatchThreshold;

  bool _isCancelled = false;
  final List<Timer> _activeTimers = [];

  void cancel() {
    _isCancelled = true;
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
  }

  void reset() {
    _isCancelled = false;
    _activeTimers.clear();
  }

  /// Performs a batched (per relay) events fetching using backfill for the given master pubkeys.
  ///
  /// Users are split into batches and distributed evenly across the [syncInterval]
  /// to avoid overwhelming relays.
  ///
  /// For example, with a 2-minute sync interval and user distribution across 3 relays:
  /// relayA -> 120 users
  /// relayB -> 30 users
  /// relayC -> 30 users
  ///
  /// - now (0s):   relayA users 1..60, relayB users 1..30, relayC users 1..30
  /// - in 40s:     relayA users 61..120
  /// - in 1m 20s:  relayA users 121..180
  Future<void> performSync({
    required List<String> masterPubkeys,
    required RequestFilter Function({required List<String> masterPubkeys}) filterBuilder,
    required DateTime lastSyncTime,
    required Duration syncInterval,
    required void Function(EventMessage) onEvent,
  }) async {
    if (_isCancelled) return;

    final optimalUserRelays = await _optimalUserRelaysService.fetch(
      masterPubkeys: masterPubkeys,
      strategy: OptimalRelaysStrategy.mostUsers,
    );

    final relaySyncFutures = optimalUserRelays.entries.map((entry) async {
      final MapEntry(key: relayUrl, value: relayMasterPubkeys) = entry;
      await _syncUsersFromRelay(
        masterPubkeys: relayMasterPubkeys,
        relayUrl: relayUrl,
        filterBuilder: filterBuilder,
        lastSyncTime: lastSyncTime,
        syncInterval: syncInterval,
        onEvent: onEvent,
      );
    });

    await Future.wait(relaySyncFutures);
  }

  Future<void> _syncUsersFromRelay({
    required List<String> masterPubkeys,
    required String relayUrl,
    required RequestFilter Function({required List<String> masterPubkeys}) filterBuilder,
    required DateTime lastSyncTime,
    required Duration syncInterval,
    required void Function(EventMessage) onEvent,
  }) async {
    if (_isCancelled) return;

    final batchedMasterPubkeys = _splitToBatches(masterPubkeys: masterPubkeys);
    final batchCount = batchedMasterPubkeys.length;
    final batchSyncFutures = batchedMasterPubkeys.asMap().entries.map((batchEntry) async {
      final MapEntry(key: batchIndex, value: batch) = batchEntry;
      await _batchDelay(
        batchIndex: batchIndex,
        batchCount: batchCount,
        syncInterval: syncInterval,
      );

      if (_isCancelled) return;

      await _eventBackfillService.startBackfill(
        latestEventTimestamp: lastSyncTime.microsecondsSinceEpoch,
        filter: filterBuilder(masterPubkeys: batch),
        actionSource: ActionSource.relayUrl(relayUrl),
        onEvent: onEvent,
      );
    });

    await Future.wait(batchSyncFutures);
  }

  /// Calculates delay for a batch to distribute syncs evenly across [syncInterval].
  ///
  /// Example with 2-minute sync interval and 3 batches:
  /// - batch 0: delay 0s   (0 * 120000 / 3)
  /// - batch 1: delay 40s  (1 * 120000 / 3)
  /// - batch 2: delay 80s  (2 * 120000 / 3)
  Future<void> _batchDelay({
    required int batchIndex,
    required int batchCount,
    required Duration syncInterval,
  }) async {
    final delayDuration = Duration(
      milliseconds: (batchIndex * syncInterval.inMilliseconds) ~/ batchCount,
    );

    if (delayDuration > Duration.zero) {
      final completer = Completer<void>();
      final timer = Timer(delayDuration, () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
      _activeTimers.add(timer);

      try {
        await completer.future;
      } finally {
        _activeTimers.remove(timer);
      }
    }
  }

  List<List<String>> _splitToBatches({required List<String> masterPubkeys}) {
    final batchCount = _calculateBatchCount(masterPubkeys.length);

    final batchSize = (masterPubkeys.length / batchCount).ceil();
    return [
      for (var i = 0; i < masterPubkeys.length; i += batchSize)
        masterPubkeys.sublist(i, (i + batchSize).clamp(0, masterPubkeys.length)),
    ];
  }

  /// Calculates dynamic batch count using exponentially growing thresholds.
  ///
  /// Example for `baseBatchThreshold = 50`:
  /// `1..50` users  -> `1` batch
  /// `51..100` users -> `2` batches
  /// `101..200` users -> `3` batches
  /// `201..400` users -> `4` batches
  /// and so on...
  int _calculateBatchCount(int pubkeysCount) {
    var batchCount = 1;
    var threshold = _baseBatchThreshold;

    while (pubkeysCount > threshold) {
      batchCount++;
      threshold *= 2;
    }

    return batchCount;
  }
}

@riverpod
BatchedSyncService batchedSyncService(Ref ref) {
  keepAliveWhenAuthenticated(ref);

  final optimalUserRelaysService = ref.watch(optimalUserRelaysServiceProvider);
  final eventBackfillService = ref.watch(eventBackfillServiceProvider);
  return BatchedSyncService(
    optimalUserRelaysService: optimalUserRelaysService,
    eventBackfillService: eventBackfillService,
    baseBatchThreshold: 50,
  );
}
