// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:ion/app/features/ion_connect/database/converters/event_reference_converter.d.dart';

@DataClassName('UserSentLike')
class UserSentLikesTable extends Table {
  TextColumn get eventReference => text().map(const EventReferenceConverter())();
  IntColumn get sentAt => integer()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, confirmed

  @override
  Set<Column> get primaryKey => {eventReference};
}
