// SPDX-License-Identifier: ice License 1.0

part of '../event_messages_database.m.dart';

class ConversationTable extends Table {
  late final id = text()();
  late final type = intEnum<ConversationType>()();
  late final joinedAt = integer()();
  late final isArchived = boolean().withDefault(const Constant(false))();
  late final isDeleted = boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

enum ConversationType {
  oneToOne,
  community,
  group,
}
