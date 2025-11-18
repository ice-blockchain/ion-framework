// SPDX-License-Identifier: ice License 1.0

part of '../chat_database.m.dart';

@TableIndex(name: 'idx_conversation_message_conversation_id', columns: {#conversationId})
@TableIndex(name: 'idx_conversation_message_event_reference', columns: {#messageEventReference})
class ConversationMessageTable extends Table {
  late final conversationId = text().references(ConversationTable, #id)();
  late final messageEventReference =
      text().map(const EventReferenceConverter()).references(EventMessageTable, #eventReference)();

  //TODO write migrations to set the default value to the current timestamp
  IntColumn get publishedAt => integer().withDefault(const Constant(0))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  @override
  Set<Column<Object>> get primaryKey => {messageEventReference};
}
