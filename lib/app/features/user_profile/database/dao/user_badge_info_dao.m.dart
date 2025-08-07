// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/database/event_messages_database.m.dart';
import 'package:ion/app/features/user/model/badges/badge_award.f.dart';
import 'package:ion/app/features/user/model/badges/badge_definition.f.dart';
import 'package:ion/app/features/user/model/badges/profile_badges.f.dart';
import 'package:ion/app/features/user_profile/database/tables/user_badge_info_table.d.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_badge_info_dao.m.g.dart';

@riverpod
UserBadgeInfoDao userBadgeInfoDao(Ref ref) {
  keepAliveWhenAuthenticated(ref);
  return UserBadgeInfoDao(db: ref.watch(eventMessagesDatabaseProvider));
}

@DriftAccessor(tables: [UserBadgeInfoTable])
class UserBadgeInfoDao extends DatabaseAccessor<EventMessagesDatabase>
    with _$UserBadgeInfoDaoMixin {
  UserBadgeInfoDao({required EventMessagesDatabase db}) : super(db);

  Future<void> insertAllProfileBadges(List<ProfileBadgesEntity> profileBadges) async {
    final databaseModels = await Future.wait<EventMessageBadgeDbModel>(
      profileBadges.map((userBadge) => userBadge.toEventMessageDbModel()),
    );

    return batch((batch) {
      batch.insertAll(db.userBadgeInfoTable, databaseModels, mode: InsertMode.insertOrReplace);
    });
  }

  Future<void> insertAllBadgeAwards(List<BadgeAwardEntity> badgeAwards) async {
    final databaseModels = await Future.wait<EventMessageBadgeDbModel>(
      badgeAwards.map((userBadge) => userBadge.toEventMessageDbModel()),
    );

    return batch((batch) {
      batch.insertAll(db.userBadgeInfoTable, databaseModels, mode: InsertMode.insertOrReplace);
    });
  }

  Future<void> insertAllBadgeDefinitions(List<BadgeDefinitionEntity> badgeDefinitions) async {
    final databaseModels = await Future.wait<EventMessageBadgeDbModel>(
      badgeDefinitions.map((userBadge) => userBadge.toEventMessageDbModel()),
    );

    return batch((batch) {
      batch.insertAll(db.userBadgeInfoTable, databaseModels, mode: InsertMode.insertOrReplace);
    });
  }

  Future<int> deleteProfileBadges(List<String> masterPubkeys) async {
    final query = delete(db.userDelegationTable)
      ..where((user) => user.masterPubkey.isIn(masterPubkeys));

    return query.go();
  }
}
