// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/notifications/data/database/notifications_database.m.dart';
import 'package:ion/app/features/feed/notifications/data/database/tables/subscribed_users_content_table.d.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscribed_users_content_dao.m.g.dart';

@Riverpod(keepAlive: true)
SubscribedUsersContentDao subscribedUsersContentDao(Ref ref) =>
    SubscribedUsersContentDao(ref.watch(notificationsDatabaseProvider));

@DriftAccessor(tables: [SubscribedUsersContentTable])
class SubscribedUsersContentDao extends DatabaseAccessor<NotificationsDatabase>
    with _$SubscribedUsersContentDaoMixin {
  SubscribedUsersContentDao(super.db);

  Future<void> insert(ContentNotification content) {
    return into(subscribedUsersContentTable).insertOnConflictUpdate(content);
  }

  Future<List<ContentNotification>> getContentAfter({
    required int limit,
    DateTime? after,
  }) async {
    final query = select(subscribedUsersContentTable)
      ..orderBy([(c) => OrderingTerm.desc(c.createdAt)])
      ..limit(limit);

    if (after != null) {
      query.where((c) => c.createdAt.isSmallerThanValue(after.microsecondsSinceEpoch));
    }

    return query.get();
  }

  Stream<int> watchUnreadCount({required DateTime after}) {
    final query = selectOnly(subscribedUsersContentTable)
      ..addColumns([subscribedUsersContentTable.rowId.count()])
      ..where(
        subscribedUsersContentTable.createdAt.isBiggerThanValue(after.microsecondsSinceEpoch),
      );

    return query
        .map((row) => row.read(subscribedUsersContentTable.rowId.count()) ?? 0)
        .watchSingle();
  }
}
