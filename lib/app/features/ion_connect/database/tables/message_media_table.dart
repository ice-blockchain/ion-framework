// SPDX-License-Identifier: ice License 1.0

part of '../event_messages_database.m.dart';

class MessageMediaTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get status => intEnum<MessageMediaStatus>()();
  TextColumn get remoteUrl => text().nullable()();
  TextColumn get cacheKey => text().nullable()();
  TextColumn get messageEventReference =>
      text().map(const EventReferenceConverter()).references(EventMessageTable, #eventReference)();
}

enum MessageMediaStatus {
  created,
  processing,
  completed,
  failed,
}
