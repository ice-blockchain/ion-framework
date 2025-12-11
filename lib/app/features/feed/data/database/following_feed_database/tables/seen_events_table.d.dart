// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:ion/app/features/feed/data/database/following_feed_database/converters/feed_modifier_converter.d.dart';
import 'package:ion/app/features/feed/data/database/following_feed_database/converters/feed_type_converter.d.dart';
import 'package:ion/app/features/ion_connect/database/converters/event_reference_converter.d.dart';

@DataClassName('SeenEvent')
class SeenEventsTable extends Table {
  IntColumn get feedType => integer().map(const FeedTypeConverter())();
  IntColumn get feedModifier => integer().map(const FeedModifierConverter())();
  TextColumn get eventReference => text().map(const EventReferenceConverter())();
  TextColumn get nextEventReference => text().map(const EventReferenceConverter()).nullable()();
  TextColumn get pubkey => text()();
  IntColumn get kind => integer().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {feedType, feedModifier, eventReference};
}
