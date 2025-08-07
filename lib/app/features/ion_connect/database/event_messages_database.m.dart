// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/database/converters/event_reference_converter.d.dart';
import 'package:ion/app/features/ion_connect/database/converters/event_tags_converter.dart';
import 'package:ion/app/features/ion_connect/database/tables/event_messages_table.d.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user_block/model/database/tables/block_event_table.d.dart';
import 'package:ion/app/features/user_block/model/database/tables/unblock_event_table.d.dart';
import 'package:ion/app/features/user_profile/database/tables/user_badge_info_table.d.dart';
import 'package:ion/app/features/user_profile/database/tables/user_delegation_table.d.dart';
import 'package:ion/app/features/user_profile/database/tables/user_metadata_table.d.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_messages_database.m.g.dart';

@Riverpod(keepAlive: true)
EventMessagesDatabase eventMessagesDatabase(Ref ref) {
  final pubkey = ref.watch(currentPubkeySelectorProvider);

  if (pubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  final database = EventMessagesDatabase(pubkey);

  onLogout(ref, database.close);

  return database;
}

@DriftDatabase(
  tables: [
    EventMessagesTable,
    UserMetadataTable,
    UserDelegationTable,
    UserBadgeInfoTable,
    BlockEventTable,
    UnblockEventTable,
  ],
)
class EventMessagesDatabase extends _$EventMessagesDatabase {
  EventMessagesDatabase(this.pubkey) : super(_openConnection(pubkey));

  final String pubkey;

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection(String pubkey) {
    return driftDatabase(name: 'event_messages_database_$pubkey');
  }
}
