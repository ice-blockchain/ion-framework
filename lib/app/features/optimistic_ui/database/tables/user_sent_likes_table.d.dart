// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:ion/app/features/ion_connect/database/converters/event_reference_converter.d.dart';

enum UserSentLikeStatus {
  pending,
  confirmed,
  failed;

  int asInt() => index;
}

@DataClassName('UserSentLike')
class UserSentLikesTable extends Table {
  TextColumn get eventReference => text().map(const EventReferenceConverter())();
  IntColumn get sentAt => integer()();
  IntColumn get status => intEnum<UserSentLikeStatus>()();

  @override
  Set<Column> get primaryKey => {eventReference};
}
