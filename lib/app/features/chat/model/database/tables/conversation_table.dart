// SPDX-License-Identifier: ice License 1.0

part of '../chat_database.m.dart';

class ConversationTable extends Table {
  late final id = text()();
  late final type = intEnum<ConversationType>()();
  late final joinedAt = integer()();
  late final isArchived = boolean().withDefault(const Constant(false))();
  late final isHidden = boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

enum ConversationType {
  direct,
  community,
  group,
}
