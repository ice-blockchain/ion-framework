// SPDX-License-Identifier: ice License 1.0

part of '../chat_database.m.dart';

@DataClassName('EventMessageDbModel')
@TableIndex(name: 'idx_event_message_created_at', columns: {#createdAt})
@TableIndex(name: 'idx_event_message_kind', columns: {#kind})
class EventMessageTable extends Table {
  TextColumn get id => text()();
  IntColumn get kind => integer()();
  TextColumn get pubkey => text()();
  TextColumn get masterPubkey => text()();
  IntColumn get createdAt => integer()();
  TextColumn get content => text()();
  TextColumn get tags => text().map(const EventTagsConverter())();
  TextColumn get eventReference => text().map(const EventReferenceConverter())();

  @override
  Set<Column> get primaryKey => {eventReference};
}
