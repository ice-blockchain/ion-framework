// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_parser.r.dart';
import 'package:ion/app/utils/directory.dart';
import 'package:ion_connect_cache/ion_connect_cache.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_connect_database_cache_notifier.r.g.dart';

abstract class DbCacheableEntity implements EntityEventSerializable {}

@Riverpod(keepAlive: true)
Future<IonConnectCacheService> ionConnectPersistentCacheService(Ref ref) async {
  const databaseName = 'ion_connect_cache';

  final appGroup = Platform.isIOS
      ? ref.watch(envProvider.notifier).get<String>(EnvVariable.FOUNDATION_APP_GROUP)
      : null;

  final executor = appGroup == null
      ? driftDatabase(name: databaseName)
      : driftDatabase(
          name: databaseName,
          native: DriftNativeOptions(
            databasePath: () async =>
                getSharedDatabasePath(databaseName: databaseName, appGroupId: appGroup),
            shareAcrossIsolates: true,
          ),
        );

  final database = IONConnectCacheDatabase(executor);
  final cacheService = IonConnectCacheServiceDriftImpl(db: database);

  onLogout(ref, cacheService.clearDatabase);

  return cacheService;
}

@riverpod
class IonConnectDatabaseCache extends _$IonConnectDatabaseCache {
  @override
  void build() {}

  Future<void> saveEntity(DbCacheableEntity entity) async {
    final cacheService = await ref.read(ionConnectPersistentCacheServiceProvider.future);

    final cacheKey = entity.toEventReference().toString();
    final eventMessage = await entity.toEntityEventMessage();

    await cacheService.save((cacheKey: cacheKey, eventMessage: eventMessage));
  }

  Future<void> saveAllEntities(List<DbCacheableEntity> entities) async {
    final cacheService = await ref.read(ionConnectPersistentCacheServiceProvider.future);

    final valuesFutures = entities.map((e) async {
      final cacheKey = e.toEventReference().toString();
      final eventMessage = await e.toEntityEventMessage();

      return (cacheKey: cacheKey, eventMessage: eventMessage);
    }).toList();

    final values = await Future.wait(valuesFutures);

    await cacheService.saveAll(values);
  }

  Future<IonConnectEntity?> get(
    String cacheKey, {
    Duration? expirationDuration,
    DatabaseCacheStrategy cacheStrategy = DatabaseCacheStrategy.alwaysReturn,
  }) async {
    final parser = ref.read(eventParserProvider);
    final cacheService = await ref.read(ionConnectPersistentCacheServiceProvider.future);

    final result = await cacheService.get(cacheKey);
    if (result == null) {
      return null;
    }

    if (cacheStrategy == DatabaseCacheStrategy.returnIfNotExpired &&
        isExpired(result.insertedAt, expirationDuration)) {
      return null;
    }

    return parser.parse(result.eventMessage);
  }

  Future<List<IonConnectEntity>> getAllFiltered({
    String? keyword,
    List<int> kinds = const [],
    List<String> cacheKeys = const [],
    Duration? expirationDuration,
    DatabaseCacheStrategy cacheStrategy = DatabaseCacheStrategy.alwaysReturn,
  }) async {
    final parser = ref.read(eventParserProvider);
    final cacheService = await ref.read(ionConnectPersistentCacheServiceProvider.future);

    final results = await cacheService.getAllFiltered(
      kinds: kinds,
      keyword: keyword,
      cacheKeys: cacheKeys,
    );

    return results.nonNulls
        .map((result) {
          if (cacheStrategy == DatabaseCacheStrategy.returnIfNotExpired &&
              isExpired(result.insertedAt, expirationDuration)) {
            return null;
          }
          return parser.parse(result.eventMessage);
        })
        .nonNulls
        .toList();
  }

  Future<void> saveEventReference(EventReference eventReference, {bool network = true}) async {
    final entity = await ref.read(
      ionConnectEntityProvider(eventReference: eventReference, network: network).future,
    );

    if (entity is DbCacheableEntity) {
      await saveEntity(entity! as DbCacheableEntity);
    }
  }

  Future<void> saveAllNonExistingReferences(List<EventReference> eventReferences) async {
    final parser = ref.read(eventParserProvider);
    final cacheService = await ref.read(ionConnectPersistentCacheServiceProvider.future);

    final existingResults = await cacheService.getAllFiltered(
      cacheKeys: eventReferences.map((e) => e.toString()).toList(),
    );

    final nonExistingRefs = eventReferences
        .toSet()
        .difference(
          existingResults
              .map((result) {
                final parsed = parser.parse(result.eventMessage);
                return parsed.toEventReference();
              })
              .nonNulls
              .toSet(),
        )
        .toList();

    const pageSize = 100;
    final entities = <DbCacheableEntity>[];
    for (var i = 0; i < nonExistingRefs.length; i += pageSize) {
      final batch = nonExistingRefs.skip(i).take(pageSize);
      final results = await Future.wait(
        batch.map(
          (eventReference) {
            return ref.read(ionConnectEntityProvider(eventReference: eventReference).future);
          },
        ),
      );
      entities.addAll(results.whereType<DbCacheableEntity>());
    }

    return saveAllEntities(entities);
  }

  Future<void> remove(String cacheKey) async {
    final cacheService = await ref.read(ionConnectPersistentCacheServiceProvider.future);

    await cacheService.remove(cacheKey);
  }

  Future<void> removeAll(List<String> cacheKeys) async {
    final cacheService = await ref.read(ionConnectPersistentCacheServiceProvider.future);

    await cacheService.removeAll(cacheKeys: cacheKeys);
  }

  bool isExpired(DateTime insertedAt, Duration? expirationDuration) {
    if (expirationDuration == null) {
      return false;
    }
    final now = DateTime.now();
    return insertedAt.add(expirationDuration).isBefore(now);
  }
}
