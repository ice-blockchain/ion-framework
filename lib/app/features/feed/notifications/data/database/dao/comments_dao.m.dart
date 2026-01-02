// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/notifications/data/database/notifications_database.m.dart';
import 'package:ion/app/features/feed/notifications/data/database/tables/comments_table.d.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comments_dao.m.g.dart';

@Riverpod(keepAlive: true)
CommentsDao commentsDao(Ref ref) => CommentsDao(db: ref.watch(notificationsDatabaseProvider));

@DriftAccessor(tables: [CommentsTable])
class CommentsDao extends DatabaseAccessor<NotificationsDatabase> with _$CommentsDaoMixin {
  CommentsDao({required NotificationsDatabase db}) : super(db);

  Future<void> insert(Comment comment) async {
    await into(db.commentsTable).insert(comment, mode: InsertMode.insertOrReplace);
  }

  Future<List<Comment>> getCommentsAfterByType({
    required int limit,
    CommentType? type,
    DateTime? after,
  }) async {
    final query = select(commentsTable)
      ..orderBy([(t) => OrderingTerm.desc(commentsTable.createdAt)])
      ..limit(limit);
    if (type != null) {
      query.where((t) => t.type.equalsValue(type));
    }
    if (after != null) {
      query.where((t) => t.createdAt.isSmallerThanValue(after.microsecondsSinceEpoch));
    }

    return query.get();
  }

  Stream<int> watchUnreadCount({required DateTime? after}) {
    final unreadCount = commentsTable.eventReference.count();
    final query = selectOnly(commentsTable)..addColumns([unreadCount]);

    if (after != null) {
      query.where(
        commentsTable.createdAt.isBiggerThanValue(after.microsecondsSinceEpoch),
      );
    }

    return query.map((row) => row.read(unreadCount)!).watchSingle();
  }
}
