// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:ion/app/features/ion_connect/database/converters/event_reference_converter.d.dart';
import 'package:ion/app/features/ion_connect/database/converters/event_tags_converter.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user_profile/database/tables/user_badge_info_table.d.dart';
import 'package:ion/app/features/user_profile/database/tables/user_delegation_table.d.dart';
import 'package:ion/app/features/user_profile/database/tables/user_metadata_table.d.dart';
import 'package:ion/app/utils/directory.dart';

part 'user_profile_database.d.g.dart';

@DriftDatabase(
  tables: [
    UserMetadataTable,
    UserDelegationTable,
    UserBadgeInfoTable,
  ],
)
class UserProfileDatabase extends _$UserProfileDatabase {
  UserProfileDatabase(
    this.masterPubkey, {
    this.appGroupId,
  }) : super(_openConnection(masterPubkey, appGroupId));

  final String masterPubkey;
  final String? appGroupId;

  @override
  int get schemaVersion => 1;

  /// Opens a connection to the database with the given pubkey
  /// Uses app group container for iOS extensions if appGroupId is provided
  static QueryExecutor _openConnection(String pubkey, String? appGroupId) {
    final databaseName = 'user_profile_database_$pubkey';
    if (appGroupId == null) {
      return driftDatabase(
        name: databaseName,
        native: DriftNativeOptions(
          setup: (database) => database.execute('PRAGMA journal_mode = WAL'),
        ),
      );
    }

    return driftDatabase(
      name: databaseName,
      native: DriftNativeOptions(
        databasePath: () async =>
            getSharedDatabasePath(databaseName: databaseName, appGroupId: appGroupId),
        shareAcrossIsolates: true,
        setup: (database) => database.execute('PRAGMA journal_mode = WAL'),
      ),
    );
  }
}
