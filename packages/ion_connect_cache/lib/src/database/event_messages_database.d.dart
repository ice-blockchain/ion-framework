// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:ion_connect_cache/src/database/tables/event_messages_table.d.dart';

part 'event_messages_database.d.g.dart';

@DriftDatabase(tables: [EventMessagesTable])
class EventMessagesDatabase extends _$EventMessagesDatabase {
  EventMessagesDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
