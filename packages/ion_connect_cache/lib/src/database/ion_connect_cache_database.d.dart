// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:ion_connect_cache/src/database/converters/event_tags_converter.dart';
import 'package:ion_connect_cache/src/database/tables/event_messages_table.d.dart';

part 'ion_connect_cache_database.d.g.dart';

@DriftDatabase(tables: [EventMessagesTable])
class IONConnectCacheDatabase extends _$IONConnectCacheDatabase {
  IONConnectCacheDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
