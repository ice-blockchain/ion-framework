// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/constants/database.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/database/converters/event_reference_converter.d.dart';
import 'package:ion/app/features/ion_connect/database/converters/event_tags_converter.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user_block/extensions/event_message.dart';
import 'package:ion/app/features/user_block/model/entities/blocked_user_entity.f.dart';
import 'package:ion/app/features/user_block/providers/blocked_users_database_provider.r.dart';
import 'package:ion/app/utils/database_isolate.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'block_user_database.m.g.dart';
part 'dao/block_event_dao.r.dart';
part 'dao/unblock_event_dao.r.dart';
part 'tables/block_event_table.dart';
part 'tables/unblock_event_table.dart';

@DriftDatabase(
  tables: [
    BlockEventTable,
    UnblockEventTable,
  ],
  daos: [BlockEventDao],
)
class BlockUserDatabase extends _$BlockUserDatabase {
  BlockUserDatabase(this.pubkey) : super(_openConnection(pubkey));

  final String pubkey;

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection(String pubkey) {
    return createDatabaseExecutorWithManualIsolate(
      databaseName: 'block_user_database_$pubkey',
      setupCallback: (database) => database.execute(DatabaseConstants.journalModeWAL),
    );
  }
}
