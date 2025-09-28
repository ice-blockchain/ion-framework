// SPDX-License-Identifier: ice License 1.0

part of '../chat_database.m.dart';

class ProcessedGiftWrapTable extends Table {
  TextColumn get eventReference =>
      text().map(const EventReferenceConverter()).references(EventMessageTable, #eventReference)();
  TextColumn get giftWrapId => text().unique()();

  @override
  Set<Column> get primaryKey => {eventReference, giftWrapId};
}
