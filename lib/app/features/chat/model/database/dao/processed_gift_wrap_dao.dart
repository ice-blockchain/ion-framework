// SPDX-License-Identifier: ice License 1.0

part of '../chat_database.m.dart';

@Riverpod(keepAlive: true)
ProcessedGiftWrapDao processedGiftWrapDao(Ref ref) =>
    ProcessedGiftWrapDao(ref.watch(chatDatabaseProvider));

@DriftAccessor(tables: [ProcessedGiftWrapTable])
class ProcessedGiftWrapDao extends DatabaseAccessor<ChatDatabase> with _$ProcessedGiftWrapDaoMixin {
  ProcessedGiftWrapDao(super.db);

  Future<void> add({required EventReference eventReference, required String giftWrapId}) async {
    await into(db.processedGiftWrapTable).insert(
      ProcessedGiftWrapTableCompanion.insert(
        eventReference: eventReference,
        giftWrapId: giftWrapId,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<bool> isGiftWrapAlreadyProcessed({required String giftWrapId}) async {
    final query = selectOnly(db.processedGiftWrapTable)
      ..addColumns([db.processedGiftWrapTable.giftWrapId])
      ..where(db.processedGiftWrapTable.giftWrapId.equals(giftWrapId))
      ..limit(1);

    final result = await query.getSingleOrNull();
    return result != null;
  }
}
