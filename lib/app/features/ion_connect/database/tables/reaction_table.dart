// SPDX-License-Identifier: ice License 1.0

part of '../event_messages_database.m.dart';

class ReactionTable extends Table {
  @ReferenceName('reactionEventReference')
  late final reactionEventReference =
      text().map(const EventReferenceConverter()).references(EventMessageTable, #eventReference)();

  @ReferenceName('messageEventReference')
  late final messageEventReference =
      text().map(const EventReferenceConverter()).references(EventMessageTable, #eventReference)();

  late final content = text()();
  late final masterPubkey = text()();
  late final isDeleted = boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {reactionEventReference, masterPubkey};
}
