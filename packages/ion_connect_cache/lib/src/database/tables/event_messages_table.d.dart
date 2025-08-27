// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:ion_connect_cache/src/database/converters/event_tags_converter.dart';

@DataClassName('EventMessageCacheDbModel')
class EventMessagesTable extends Table {
  TextColumn get eventReference => text()();
  IntColumn get kind => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get insertedAt => integer()();
  TextColumn get masterPubkey => text()();
  TextColumn get content => text()();
  TextColumn get tags => text().map(const EventTagsConverter())();
  TextColumn get sig => text().nullable()();
  TextColumn get id => text()();
  TextColumn get pubkey => text()();

  @override
  Set<Column> get primaryKey => {eventReference};
}
