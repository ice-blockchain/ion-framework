// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/database/converters/event_reference_converter.d.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/optimistic_ui/database/tables/user_sent_likes_table.d.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'optimistic_ui_database.m.g.dart';

@Riverpod(keepAlive: true)
OptimisticUiDatabase optimisticUiDatabase(Ref ref) {
  final pubkey = ref.watch(currentPubkeySelectorProvider);

  if (pubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  final database = OptimisticUiDatabase(pubkey);

  onLogout(ref, database.close);

  return database;
}

@DriftDatabase(
  tables: [
    UserSentLikesTable,
  ],
)
class OptimisticUiDatabase extends _$OptimisticUiDatabase {
  OptimisticUiDatabase(this.pubkey) : super(_openConnection(pubkey));

  final String pubkey;

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
    );
  }

  static QueryExecutor _openConnection(String pubkey) {
    return driftDatabase(
      name: 'optimistic_ui_database_$pubkey',
      native: DriftNativeOptions(
        setup: (database) => database.execute('PRAGMA journal_mode = WAL'),
      ),
    );
  }
}
