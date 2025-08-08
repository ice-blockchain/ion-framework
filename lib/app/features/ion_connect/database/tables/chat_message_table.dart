// SPDX-License-Identifier: ice License 1.0

part of '../event_messages_database.m.dart';

class ConversationMessageTable extends Table {
  late final conversationId = text().references(ConversationTable, #id)();
  late final messageEventReference =
      text().map(const EventReferenceConverter()).references(EventMessageTable, #eventReference)();

  @override
  Set<Column<Object>> get primaryKey => {messageEventReference};
}
