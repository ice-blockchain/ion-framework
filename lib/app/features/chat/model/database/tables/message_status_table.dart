// SPDX-License-Identifier: ice License 1.0

part of '../chat_database.m.dart';

@TableIndex(
  name: 'idx_message_status_reference_status',
  columns: {#messageEventReference, #status},
)
class MessageStatusTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get messageEventReference =>
      text().map(const EventReferenceConverter()).references(EventMessageTable, #eventReference)();
  TextColumn get pubkey => text()();
  TextColumn get masterPubkey => text()();
  IntColumn get status => intEnum<MessageDeliveryStatus>()();
}
