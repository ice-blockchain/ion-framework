// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_parser.r.dart';
import 'package:ion/app/features/ion_connect/repository/event_messages_repository.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_connect_db_cache_notifier.r.g.dart';

abstract class DbCacheableEntity implements EntityEventSerializable {}

@riverpod
class IonConnectDbCache extends _$IonConnectDbCache {
  @override
  FutureOr<void> build() async {}

  Stream<List<IonConnectEntity>> watch(List<EventReference> eventReferences) {
    final eventMessagesStream =
        ref.watch(eventMessagesRepositoryProvider).watchAll(eventReferences);
    final parser = ref.read(eventParserProvider);
    return eventMessagesStream.map((eventMessages) => eventMessages.map(parser.parse).toList());
  }

  Future<List<IonConnectEntity>> getAll(List<EventReference> eventReferences) async {
    final eventMessages = await ref.read(eventMessagesRepositoryProvider).getAll(eventReferences);
    final parser = ref.read(eventParserProvider);
    return eventMessages.map(parser.parse).toList();
  }

  Future<List<IonConnectEntity>> getFiltered({
    required String query,
    List<int>? kinds,
  }) async {
    final results =
        await ref.read(eventMessagesRepositoryProvider).getFiltered(query: query, kinds: kinds);
    final parser = ref.read(eventParserProvider);
    return results.map((item) => parser.parse(item.eventMessage)).toList();
  }

  Future<IonConnectEntity?> get(EventReference eventReference) async {
    final eventMessages = await ref.read(eventMessagesRepositoryProvider).getAll([eventReference]);
    final parser = ref.read(eventParserProvider);
    return eventMessages.isNotEmpty ? parser.parse(eventMessages.first) : null;
  }

  Future<void> saveRef(
    EventReference eventReference, {
    bool network = true,
  }) async {
    final entity = await ref.read(
      ionConnectEntityProvider(eventReference: eventReference, network: network).future,
    );
    if (entity is EntityEventSerializable) {
      await save(entity! as EntityEventSerializable);
    }
  }

  Future<void> save(EntityEventSerializable eventSerializable) async {
    final eventMessage = await eventSerializable.toEntityEventMessage();
    final eventReference = eventSerializable.toEventReference();
    await ref.read(eventMessagesRepositoryProvider).save(eventMessage, eventReference);
  }

  Future<void> saveAll(List<EntityEventSerializable> eventSerializables) async {
    if (eventSerializables.isEmpty) return;
    final eventMessages = await Future.wait(
      eventSerializables.map(
        (eventSerializable) => Future.value(eventSerializable.toEntityEventMessage()),
      ),
    );
    final eventReferences = eventSerializables
        .map((eventSerializable) => eventSerializable.toEventReference())
        .toList();
    await ref.read(eventMessagesRepositoryProvider).saveAll(eventMessages, eventReferences);
  }

  Future<void> saveAllNonExistingRefs(List<EventReference> eventRefs) async {
    final nonExistingRefs =
        await ref.read(eventMessagesRepositoryProvider).getNonSavedRefs(eventRefs);
    const pageSize = 100;
    final entities = <EntityEventSerializable>[];
    for (var i = 0; i < nonExistingRefs.length; i += pageSize) {
      final batch = nonExistingRefs.skip(i).take(pageSize);
      final results = await Future.wait(
        batch.map(
          (eventReference) =>
              ref.read(ionConnectEntityProvider(eventReference: eventReference).future),
        ),
      );
      entities.addAll(results.whereType<EntityEventSerializable>());
    }

    return saveAll(entities);
  }

  Future<void> removeAll(List<EventReference> eventReferences) {
    return ref.read(eventMessagesRepositoryProvider).removeAll(eventReferences);
  }
}
