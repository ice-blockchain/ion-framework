// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/notifications/data/database/notifications_database.m.dart';
import 'package:ion/app/features/feed/notifications/data/database/tables/followers_table.d.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'followers_dao.m.g.dart';

@Riverpod(keepAlive: true)
FollowersDao followersDao(Ref ref) => FollowersDao(db: ref.watch(notificationsDatabaseProvider));

@DriftAccessor(tables: [FollowersTable])
class FollowersDao extends DatabaseAccessor<NotificationsDatabase> with _$FollowersDaoMixin {
  FollowersDao({required NotificationsDatabase db}) : super(db);

  Future<void> insert(Follower follower) async {
    await into(db.followersTable).insert(follower, mode: InsertMode.insertOrReplace);
  }

  Future<List<AggregatedFollowersResult>> getAggregated() {
    return db.aggregatedFollowers().get();
  }

  Future<List<AggregatedFollowersAfterResult>> getAggregatedAfter({
    required int limit,
    DateTime? after,
  }) {
    return db
        .aggregatedFollowersAfter(
          after?.microsecondsSinceEpoch ?? 0x7FFFFFFFFFFFFFFF,
          //max int for the last_created_at < ?1 condition as it doesn't work with null
          limit,
        )
        .get();
  }

  Future<DateTime?> getLastCreatedAt() async {
    final maxCreatedAt = followersTable.createdAt.max();
    final max = await (selectOnly(followersTable)..addColumns([maxCreatedAt]))
        .map((row) => row.read(maxCreatedAt))
        .getSingleOrNull();
    return max?.toDateTime;
  }

  Future<DateTime?> getFirstCreatedAt({DateTime? after}) async {
    final firstCreatedAt = followersTable.createdAt.min();
    final query = selectOnly(followersTable)..addColumns([firstCreatedAt]);
    if (after != null) {
      query.where(followersTable.createdAt.isBiggerThanValue(after.microsecondsSinceEpoch));
    }
    final min = await query.map((row) => row.read(firstCreatedAt)).getSingleOrNull();
    return min?.toDateTime;
  }

  Stream<int> watchUnreadCount({required DateTime? after}) {
    final unreadCount = followersTable.pubkey.count();
    final query = selectOnly(followersTable)..addColumns([unreadCount]);

    if (after != null) {
      query.where(
        followersTable.createdAt.isBiggerThanValue(after.microsecondsSinceEpoch),
      );
    }

    return query.map((row) => row.read(unreadCount)!).watchSingle();
  }
}
