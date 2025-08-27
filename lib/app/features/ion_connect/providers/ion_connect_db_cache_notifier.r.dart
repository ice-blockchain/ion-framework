// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
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
Future<IonConnectCacheServiceDriftImpl> ionConnectPersistentCacheService(Ref ref) async {
  final path = await getApplicationDocumentsDirectory();
  return IonConnectCacheServiceDriftImpl.persistent(
    '${path.path}/ion_connect_cache.sqlite',
  );
}

@riverpod
class IonConnectDbCache extends _$IonConnectDbCache {
  @override
  void build() async {}

  Stream<List<IonConnectEntity>> watchAll(List<EventReference> eventReferences) async* {
    final parser = ref.read(eventParserProvider);
    final cacheService = await ref.read(ionConnectPersistentCacheServiceProvider.future);

    final eventMessagesStream =
        cacheService.watchAll(eventReferences.map((e) => e.toString()).toList());

    yield* eventMessagesStream.map((eventMessages) => eventMessages.map(parser.parse).toList());
  }

  Future<IonConnectEntity?> get(EventReference eventReference) async {
    final parser = ref.read(eventParserProvider);
    final cacheService = await ref.read(ionConnectPersistentCacheServiceProvider.future);

    final eventMessage = await cacheService.get(eventReference.toString());

    if (eventMessage == null) {
      return null;
    }

    return parser.parse(eventMessage);
  }

  Future<List<IonConnectEntity>> getAll(List<EventReference> eventReferences) async {
    final parser = ref.read(eventParserProvider);
    final cacheService = await ref.read(ionConnectPersistentCacheServiceProvider.future);

    final eventMessages =
        await cacheService.getAll(eventReferences.map((e) => e.toString()).toList());

    return eventMessages.map(parser.parse).toList();
  }

  Future<List<IonConnectEntity>> getAllFiltered({
    required String query,
    List<int> kinds = const [],
    List<EventReference> eventReferences = const [],
  }) async {
    final parser = ref.read(eventParserProvider);
    final cacheService = await ref.read(ionConnectPersistentCacheServiceProvider.future);

    final eventMessages = await cacheService.getAllFiltered(
      query: query,
      kinds: kinds,
      eventReferences: eventReferences.map((e) => e.toString()).toList(),
    );

    return eventMessages.map(parser.parse).toList();
  }

  Future<void> save(EntityEventSerializable eventSerializable) async {
    final cacheService = await ref.read(ionConnectPersistentCacheServiceProvider.future);

    final eventReference = eventSerializable.toEventReference();
    final eventMessage = await eventSerializable.toEntityEventMessage();

    await cacheService.save((eventReference.masterPubkey, eventReference.toString(), eventMessage));
  }

  Future<void> saveAll(List<EntityEventSerializable> eventSerializables) async {
    final cacheService = await ref.read(ionConnectPersistentCacheServiceProvider.future);

    final valuesFutures = eventSerializables.map((e) async {
      final eventMessage = await e.toEntityEventMessage();

      return (
        eventMessage.masterPubkey,
        e.toEventReference().toString(),
        eventMessage,
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
    final cacheService = await ref.read(ionConnectPersistentCacheServiceProvider.future);

    final nonExistingRefs =
        await cacheService.getAllNonExistingReferences(eventRefs.map((e) => e.toString()).toSet());

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

    await cacheService.removeAll(eventReferences.map((e) => e.toString()).toList());
  }
}
