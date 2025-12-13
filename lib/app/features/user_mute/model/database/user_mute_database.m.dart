// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/constants/database.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/database/converters/event_reference_converter.d.dart';
import 'package:ion/app/features/ion_connect/database/converters/event_tags_converter.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user_mute/extensions/event_message.dart';
import 'package:ion/app/features/user_mute/model/entities/user_mute_entity.f.dart';
import 'package:ion/app/features/user_mute/providers/user_mute_database_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_mute_database.m.g.dart';
part 'dao/user_mute_event_dao.r.dart';
part 'tables/user_mute_event_table.dart';

@DriftDatabase(
  tables: [UserMuteEventTable],
  daos: [UserMuteEventDao],
)
class UserMuteDatabase extends _$UserMuteDatabase {
  UserMuteDatabase(this.pubkey) : super(_openConnection(pubkey));

  final String pubkey;

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection(String pubkey) {
    return driftDatabase(
      name: 'user_mute_database_$pubkey',
      native: DriftNativeOptions(
        setup: (database) => database.execute(DatabaseConstants.journalModeWAL),
      ),
    );
  }
}
