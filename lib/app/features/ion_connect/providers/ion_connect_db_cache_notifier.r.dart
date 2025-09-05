// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_parser.r.dart';
import 'package:ion_connect_cache/ion_connect_cache.dart';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_connect_db_cache_notifier.r.g.dart';

abstract class DbCacheableEntity implements EntityEventSerializable {}

@Riverpod(keepAlive: true)
Future<IonConnectCacheService> ionConnectPersistentCacheService(Ref ref) async {
  final path = await getApplicationDocumentsDirectory();
  final cacheService = IonConnectCacheServiceDriftImpl.persistent(
    '${path.path}/ion_connect_cache.sqlite',
  );

  onLogout(ref, cacheService.clearDatabase);

  return cacheService;
}

@riverpod
class IonConnectDatabaseCache extends _$IonConnectDatabaseCache {
  @override
  void build() {}

  Stream<List<IonConnectEntity>> watchAll(List<EventReference> eventReferences) async* {
    final parser = ref.read(eventParserProvider);
    final cacheService = await ref.read(ionConnectPersistentCacheServiceProvider.future);

    final eventMessagesStream =
        cacheService.watchAll(cacheKeys: eventReferences.map((e) => e.toString()).toList());

    yield* eventMessagesStream.map((eventMessages) => eventMessages.map(parser.parse).toList());
  }

  bool isExpired(DateTime insertedAt, Duration? expirationDuration) {
    if (expirationDuration == null) {
      return false;
    }
    final now = DateTime.now();
    return insertedAt.add(expirationDuration).isBefore(now);
  }

  Future<IonConnectEntity?> get(
    EventReference eventReference, {
    Duration? expirationDuration,
  }) async {
    final parser = ref.read(eventParserProvider);
    final cacheService = await ref.read(ionConnectPersistentCacheServiceProvider.future);

    final result = await cacheService.get(eventReference.toString());
    if (result == null) {
      return null;
    }

    if (isExpired(result.insertedAt, expirationDuration)) {
      return null;
    }

    return parser.parse(result.eventMessage);
  }

  Future<List<IonConnectEntity>> getAll(
    List<EventReference> eventReferences, {
    Duration? expirationDuration,
  }) async {
    final parser = ref.read(eventParserProvider);
    final cacheService = await ref.read(ionConnectPersistentCacheServiceProvider.future);

    final results = await cacheService.getAllFiltered(
      cacheKeys: eventReferences.map((e) => e.toString()).toList(),
    );

    return results.nonNulls
        .map((result) {
          if (isExpired(result.insertedAt, expirationDuration)) {
            return null;
          }
          return parser.parse(result.eventMessage);
        })
        .nonNulls
        .toList();
  }

  Future<List<IonConnectEntity>> getAllFiltered({
    required String keyword,
    List<int> kinds = const [],
    List<EventReference> eventReferences = const [],
    Duration? expirationDuration,
  }) async {
    final parser = ref.read(eventParserProvider);
    final cacheService = await ref.read(ionConnectPersistentCacheServiceProvider.future);

    final results = await cacheService.getAllFiltered(
      kinds: kinds,
      keyword: keyword,
      cacheKeys: eventReferences.map((e) => e.toString()).toList(),
    );

    return results.nonNulls
        .map((result) {
          if (isExpired(result.insertedAt, expirationDuration)) {
            return null;
          }
          return parser.parse(result.eventMessage);
        })
        .nonNulls
        .toList();
  }

  Future<void> save(EntityEventSerializable eventSerializable) async {
    final cacheService = await ref.read(ionConnectPersistentCacheServiceProvider.future);

    final eventReference = eventSerializable.toEventReference();
    final eventMessage = await eventSerializable.toEntityEventMessage();

    await cacheService.save(
      (cacheKey: eventReference.toString(), eventMessage: eventMessage),
    );
  }

  Future<void> saveAll(List<EntityEventSerializable> eventSerializables) async {
    final cacheService = await ref.read(ionConnectPersistentCacheServiceProvider.future);

    final valuesFutures = eventSerializables.map((e) async {
      final eventMessage = await e.toEntityEventMessage();

      return (
        eventMessage: eventMessage,
        cacheKey: e.toEventReference().toString(),
      );
    }).toList();

    final values = await Future.wait(valuesFutures);

    await cacheService.saveAll(values);
  }

  Future<void> saveEventReference(
    EventReference eventReference, {
    bool network = true,
  }) async {
    final entity = await ref.read(
      ionConnectEntityProvider(eventReference: eventReference, network: network).future,
    );

    if (entity != null && entity is EntityEventSerializable) {
      await save(entity as EntityEventSerializable);
    }
  }

  Future<void> saveAllNonExistingRefs(List<EventReference> eventRefs) async {
    final parser = ref.read(eventParserProvider);
    final cacheService = await ref.read(ionConnectPersistentCacheServiceProvider.future);

    final existingResults = await cacheService.getAllFiltered(
      cacheKeys: eventRefs.map((e) => e.toString()).toList(),
    );

    final nonExistingRefs = eventRefs
        .map((e) => e.toString())
        .toSet()
        .difference(
          existingResults
              .map((result) {
                if (result == null) {
                  return null;
                }

                final parsed = parser.parse(result.eventMessage);
                return parsed.toEventReference().toString();
              })
              .nonNulls
              .toSet(),
        )
        .toList();

    const pageSize = 100;
    final entities = <EntityEventSerializable>[];
    for (var i = 0; i < nonExistingRefs.length; i += pageSize) {
      final batch = nonExistingRefs.skip(i).take(pageSize);
      final results = await Future.wait(
        batch.map(
          (eventReference) {
            final eventRef = EventReference.fromEncoded(eventReference);
            return ref.read(ionConnectEntityProvider(eventReference: eventRef).future);
          },
        ),
      );
      entities.addAll(results.whereType<EntityEventSerializable>());
    }

    return saveAll(entities);
  }

  Future<void> removeAll(List<EventReference> eventReferences) async {
    final cacheService = await ref.read(ionConnectPersistentCacheServiceProvider.future);

    await cacheService.removeAll(cacheKeys: eventReferences.map((e) => e.toString()).toList());
  }
}
