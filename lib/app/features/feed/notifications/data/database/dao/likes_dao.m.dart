// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/notifications/data/database/notifications_database.m.dart';
import 'package:ion/app/features/feed/notifications/data/database/tables/likes_table.d.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'likes_dao.m.g.dart';

@Riverpod(keepAlive: true)
LikesDao likesDao(Ref ref) => LikesDao(db: ref.watch(notificationsDatabaseProvider));

@DriftAccessor(tables: [LikesTable])
class LikesDao extends DatabaseAccessor<NotificationsDatabase> with _$LikesDaoMixin {
  LikesDao({required NotificationsDatabase db}) : super(db);

  Future<void> insert(Like like) async {
    await into(db.likesTable).insert(like, mode: InsertMode.insertOrReplace);
  }

  Future<List<AggregatedLikesResult>> getAggregated() {
    return db.aggregatedLikes().get();
  }

  Future<List<AggregatedLikesAfterResult>> getAggregatedAfter({
    required int limit,
    DateTime? after,
  }) {
    return db
        .aggregatedLikesAfter(
          after?.microsecondsSinceEpoch ?? 0x7FFFFFFFFFFFFFFF,
          //max int for the last_created_at < ?1 condition as it doesn't work with null
          limit,
        )
        .get();
  }

  Stream<int> watchUnreadCount({required DateTime? after}) {
    final unreadCount = likesTable.eventReference.count();
    final query = selectOnly(likesTable)..addColumns([unreadCount]);

    if (after != null) {
      query.where(
        likesTable.createdAt.isBiggerThanValue(after.microsecondsSinceEpoch),
      );
    }

    return query.map((row) => row.read(unreadCount)!).watchSingle();
  }
}
