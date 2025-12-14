// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_connect_cache.r.g.dart';

final _ionConnectCacheStreamController = StreamController<IonConnectEntity>.broadcast();

mixin CacheableEntity on IonConnectEntity {
  String get cacheKey => cacheKeyBuilder(eventReference: toEventReference());

  static String cacheKeyBuilder({required EventReference eventReference}) =>
      eventReference.toString();
}

class CacheEntry {
  CacheEntry({
    required this.entity,
    required this.createdAt,
  });

  final CacheableEntity entity;
  final DateTime createdAt;
}

@Riverpod(keepAlive: true)
class IonConnectCache extends _$IonConnectCache {
  final List<DbCacheableEntity> _pendingDbEntities = [];
  Timer? _batchSaveTimer;
  static const _batchSaveDelay = Duration(milliseconds: 1000);
  static const _batchSize = 50;

  @override
  Map<String, CacheEntry> build() {
    ref.onDispose(() {
      _batchSaveTimer?.cancel();
    });
    onLogout(ref, () {
      state = {};
      _pendingDbEntities.clear();
      _batchSaveTimer?.cancel();
    });
    onUserSwitch(ref, () {
      state = {};
      _pendingDbEntities.clear();
      _batchSaveTimer?.cancel();
    });
    return {};
  }

  Future<void> cache(IonConnectEntity entity, {bool waitForSave = false}) async {
    if (entity is CacheableEntity) {
      final entry = CacheEntry(
        entity: entity,
        createdAt: DateTime.now(),
      );

      state = {...state, entity.cacheKey: entry};

      _ionConnectCacheStreamController.sink.add(entity);
    }

    if (entity is DbCacheableEntity) {
      _pendingDbEntities.add(entity as DbCacheableEntity);

      if (_pendingDbEntities.length >= _batchSize) {
        if (waitForSave) {
          await _flushPendingEntitiesSync();
        } else {
          _flushPendingEntities();
        }
      } else {
        if (waitForSave) {
          await _flushPendingEntitiesSync();
        } else {
          _scheduleBatchSave();
        }
      }
    }
  }

  void _scheduleBatchSave() {
    _batchSaveTimer?.cancel();
    _batchSaveTimer = Timer(_batchSaveDelay, _flushPendingEntities);
  }

  void _flushPendingEntities() {
    if (_pendingDbEntities.isEmpty) {
      return;
    }

    final entitiesToSave = List<DbCacheableEntity>.from(_pendingDbEntities);
    _pendingDbEntities.clear();
    _batchSaveTimer?.cancel();

    unawaited(
      ref.read(ionConnectDatabaseCacheProvider.notifier).saveAllEntities(entitiesToSave),
    );
  }

  Future<void> _flushPendingEntitiesSync() async {
    if (_pendingDbEntities.isEmpty) {
      return;
    }

    final entitiesToSave = List<DbCacheableEntity>.from(_pendingDbEntities);
    _pendingDbEntities.clear();
    _batchSaveTimer?.cancel();

    await ref.read(ionConnectDatabaseCacheProvider.notifier).saveAllEntities(entitiesToSave);
  }

  void remove(String key) {
    state = {...state}..remove(key);
    ref.read(ionConnectDatabaseCacheProvider.notifier).remove(key);
  }
}

@Riverpod(keepAlive: true)
Raw<Stream<IonConnectEntity>> ionConnectCacheStream(Ref ref) {
  return _ionConnectCacheStreamController.stream;
}

// TODO:
// Move to a generic family provider instead of current `ionConnectCacheProvider.select(cacheSelector<...>())` function
// when riverpod_generator v3 is released:
// https://pub.dev/packages/riverpod_generator/versions/3.0.0-dev.11/changelog#300-dev7---2023-10-29
T? Function(Map<String, CacheEntry>) cacheSelector<T extends IonConnectEntity>(
  String key, {
  Duration? expirationDuration,
}) {
  return (Map<String, CacheEntry> state) {
    final entry = state[key];

    if (entry == null) return null;

    if (expirationDuration != null &&
        entry.createdAt.isBefore(DateTime.now().subtract(expirationDuration))) {
      return null;
    }
    return entry.entity as T;
  };
}
