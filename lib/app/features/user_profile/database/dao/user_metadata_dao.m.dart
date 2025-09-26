// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user_profile/database/tables/user_metadata_table.d.dart';
import 'package:ion/app/features/user_profile/database/user_profile_database.d.dart';
import 'package:ion/app/features/user_profile/providers/user_profile_database_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_metadata_dao.m.g.dart';

@riverpod
UserMetadataDao userMetadataDao(Ref ref) {
  keepAliveWhenAuthenticated(ref);
  return UserMetadataDao(db: ref.watch(userProfileDatabaseProvider));
}

@DriftAccessor(tables: [UserMetadataTable])
class UserMetadataDao extends DatabaseAccessor<UserProfileDatabase> with _$UserMetadataDaoMixin {
  UserMetadataDao({required UserProfileDatabase db}) : super(db);

  Future<void> insertAll(List<UserMetadataEntity> usersMetadata) async {
    final databaseModels = await Future.wait<EventMessageMetadataDbModel>(
      usersMetadata.map((userMetadata) => userMetadata.toEventMessageDbModel()),
    );

    return batch((batch) {
      batch.insertAll(db.userMetadataTable, databaseModels, mode: InsertMode.insertOrReplace);
    });
  }

  Future<void> insert(UserMetadataEntity userMetadata) async {
    final eventMessageDbModel = await userMetadata.toEventMessageDbModel();
    await into(db.userMetadataTable).insert(eventMessageDbModel, mode: InsertMode.insertOrReplace);
  }

  Future<UserMetadataEntity?> get(String masterPubkey) async {
    final query = select(db.userMetadataTable)
      ..where((user) => user.masterPubkey.equals(masterPubkey))
      ..limit(1);

    final model = await query.getSingleOrNull();

    return model == null ? null : UserMetadataEntityExtension.fromEventMessageDbModel(model);
  }

  Stream<UserMetadataEntity?> watch(String masterPubkey) {
    final query = select(db.userMetadataTable)
      ..where((user) => user.masterPubkey.equals(masterPubkey))
      ..limit(1);

    return query.watchSingleOrNull().map(
          (model) =>
              model == null ? null : UserMetadataEntityExtension.fromEventMessageDbModel(model),
        );
  }

  Future<Set<String>> getExistingMasterPubkeys() async {
    final query = select(db.userMetadataTable);

    final userMetadataModels = await query.get();
    return userMetadataModels.map((model) => model.masterPubkey).toSet();
  }

  Future<int> deleteMetadata(List<String> masterPubkeys) async {
    final query = delete(db.userMetadataTable)
      ..where((user) => user.masterPubkey.isIn(masterPubkeys));

    return query.go();
  }
}
