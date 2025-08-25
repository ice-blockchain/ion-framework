// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';

@DataClassName('EventMessageCacheDbModel')
class EventMessagesTable extends Table {
  TextColumn get id => text()();
  IntColumn get kind => integer()();
  TextColumn get pubkey => text()();
  TextColumn get masterPubkey => text()();
  IntColumn get createdAt => integer()();
  TextColumn get sig => text().nullable()();
  TextColumn get content => text()();
  //TextColumn get tags => text().map(const EventTagsConverter())();
  //TextColumn get eventReference => text().map(const EventReferenceConverter())();

  @override
  //Set<Column> get primaryKey => {eventReference};
  Set<Column> get primaryKey => {id};
}
