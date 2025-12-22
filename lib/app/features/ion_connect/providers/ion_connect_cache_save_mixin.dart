// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';

mixin IonConnectCacheSaveMixin {
  final List<DbCacheableEntity> _pendingDbEntities = [];
  Completer<void>? _currentBatchCompleter;
  Timer? _batchSaveTimer;
  Future<void>? _flushInProgress;

  Duration get batchSaveDelay => const Duration(milliseconds: 500);
  int get batchSize => 40;
  Duration get saveTimeout => const Duration(seconds: 30);

  void disposeSaveQueue() {
    _batchSaveTimer?.cancel();
    _batchSaveTimer = null;
    if (_currentBatchCompleter != null && !_currentBatchCompleter!.isCompleted) {
      _currentBatchCompleter!.complete();
    }
    _pendingDbEntities.clear();
    _currentBatchCompleter = null;
    _flushInProgress = null;
  }

  Future<void> saveEntity(DbCacheableEntity entity, Ref ref) {
    _currentBatchCompleter ??= Completer<void>();
    final completer = _currentBatchCompleter!;

    _pendingDbEntities.add(entity);

    if (_pendingDbEntities.length >= batchSize) {
      _batchSaveTimer?.cancel();
      _batchSaveTimer = null;
      _flushPendingEntities(ref);
    } else {
      _scheduleBatchSave(ref);
    }

    return completer.future;
  }

  void _scheduleBatchSave(Ref ref) {
    _batchSaveTimer?.cancel();
    _batchSaveTimer = Timer(batchSaveDelay, () {
      _flushPendingEntities(ref);
    });
  }

  void _flushPendingEntities(Ref ref) {
    if (_flushInProgress != null) {
      return;
    }

    if (_pendingDbEntities.isEmpty) {
      if (_currentBatchCompleter != null && !_currentBatchCompleter!.isCompleted) {
        _currentBatchCompleter!.complete();
      }
      _currentBatchCompleter = null;
      return;
    }

    _currentBatchCompleter ??= Completer<void>();
    final completer = _currentBatchCompleter!;

    final entitiesToSave = List<DbCacheableEntity>.from(_pendingDbEntities);
    _pendingDbEntities.clear();
    _currentBatchCompleter = null;
    _batchSaveTimer?.cancel();

    try {
      final databaseCacheNotifier = ref.read(ionConnectDatabaseCacheProvider.notifier);

      _flushInProgress = databaseCacheNotifier.saveAllEntities(entitiesToSave).timeout(
        saveTimeout,
        onTimeout: () {
          throw TimeoutException('SaveAllEntities timeout after ${saveTimeout.inSeconds} seconds');
        },
      ).then(
        (_) {
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onError: (Object error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
      ).whenComplete(() {
        _flushInProgress = null;
        if (_pendingDbEntities.isNotEmpty) {
          _scheduleBatchSave(ref);
        }
      });

      unawaited(_flushInProgress);
    } catch (e) {
      _flushInProgress = null;
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      rethrow;
    }
  }
}
