// SPDX-License-Identifier: ice License 1.0

part of '../chat_database.m.dart';

@riverpod
MessageMediaDao messageMediaDao(Ref ref) => MessageMediaDao(ref.watch(chatDatabaseProvider));

@DriftAccessor(
  tables: [
    MessageMediaTable,
  ],
)
class MessageMediaDao extends DatabaseAccessor<ChatDatabase> with _$MessageMediaDaoMixin {
  MessageMediaDao(super.db);

  Future<int> add({
    required EventReference eventReference,
    required MessageMediaStatus status,
    String? cacheKey,
    String? remoteUrl,
  }) async {
    final existRecord = await (select(messageMediaTable)
          ..where((t) => t.messageEventReference.equalsValue(eventReference))
          ..where((t) => t.remoteUrl.equalsNullable(remoteUrl))
          ..limit(1))
        .getSingleOrNull();

    if (existRecord != null) {
      await updateById(
        existRecord.id,
        eventReference,
        remoteUrl!,
        status,
      );
      return existRecord.id;
    }
    return into(messageMediaTable).insert(
      MessageMediaTableCompanion(
        messageEventReference: Value(eventReference),
        status: Value(status),
        cacheKey: Value(cacheKey),
        remoteUrl: Value(remoteUrl),
      ),
    );
  }

  Stream<List<MessageMediaTableData>> watchByEventId(EventReference eventReference) {
    return (select(messageMediaTable)
          ..where((t) => t.messageEventReference.equalsValue(eventReference)))
        .watch()
        .map((items) {
      final seen = <String?>{};
      return items.where((item) {
        if (item.remoteUrl == null) return true;
        return seen.add(item.remoteUrl);
      }).toList();
    });
  }

  Future<void> updateById(
    int id,
    EventReference eventReference,
    String remoteUrl,
    MessageMediaStatus status,
  ) async {
    await (update(messageMediaTable)..where((t) => t.id.equals(id))).write(
      MessageMediaTableCompanion(
        messageEventReference: Value(eventReference),
        remoteUrl: Value(remoteUrl),
        status: Value(status),
      ),
    );
  }

  Future<void> cancel(int id) async {
    await (delete(messageMediaTable)..where((t) => t.id.equals(id))).go();
  }

  Future<List<int>> addBatch({
    required EventReference eventReference,
    required List<String> cacheKeys,
  }) async {
    await batch((b) {
      b
        ..deleteWhere(
          messageMediaTable,
          (t) => t.messageEventReference.equalsValue(eventReference),
        )
        ..insertAll(
          messageMediaTable,
          cacheKeys
              .map(
                (cacheKey) => MessageMediaTableCompanion(
                  messageEventReference: Value(eventReference),
                  cacheKey: Value(cacheKey),
                  status: const Value(MessageMediaStatus.processing),
                ),
              )
              .toList(),
          mode: InsertMode.insertOrIgnore,
        );
    });
    final result = await (select(messageMediaTable)
          ..where((t) => t.messageEventReference.equalsValue(eventReference)))
        .get();
    return result.map((e) => e.id).toList();
  }
}
