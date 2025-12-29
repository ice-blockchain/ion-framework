// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/notifications/data/database/notifications_database.m.dart';
import 'package:ion/app/features/feed/notifications/data/database/tables/token_launch_table.d.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_launch_dao.m.g.dart';

@Riverpod(keepAlive: true)
TokenLaunchDao tokenLaunchDao(Ref ref) =>
    TokenLaunchDao(db: ref.watch(notificationsDatabaseProvider));

@DriftAccessor(tables: [TokenLaunchTable])
class TokenLaunchDao extends DatabaseAccessor<NotificationsDatabase> with _$TokenLaunchDaoMixin {
  TokenLaunchDao({required NotificationsDatabase db}) : super(db);

  Future<void> insert(TokenLaunch tokenLaunch) async {
    await into(db.tokenLaunchTable).insert(tokenLaunch, mode: InsertMode.insertOrReplace);
  }

  Future<List<TokenLaunch>> getAll() async {
    return (select(tokenLaunchTable)
          ..orderBy([(t) => OrderingTerm.desc(tokenLaunchTable.createdAt)]))
        .get();
  }

  Future<List<TokenLaunch>> getTokenLaunchesAfter({
    required int limit,
    DateTime? after,
  }) async {
    final query = select(tokenLaunchTable)
      ..orderBy([(t) => OrderingTerm.desc(tokenLaunchTable.createdAt)])
      ..limit(limit);

    if (after != null) {
      query.where((t) => t.createdAt.isBiggerThanValue(after.microsecondsSinceEpoch));
    }

    return query.get();
  }

  Future<DateTime?> getLastCreatedAt() async {
    final maxCreatedAt = tokenLaunchTable.createdAt.max();
    final max = await (selectOnly(tokenLaunchTable)..addColumns([maxCreatedAt]))
        .map((row) => row.read(maxCreatedAt))
        .getSingleOrNull();
    return max?.toDateTime;
  }

  Future<DateTime?> getFirstCreatedAt({DateTime? after}) async {
    final firstCreatedAt = tokenLaunchTable.createdAt.min();
    final query = selectOnly(tokenLaunchTable)..addColumns([firstCreatedAt]);
    if (after != null) {
      query.where(tokenLaunchTable.createdAt.isBiggerThanValue(after.microsecondsSinceEpoch));
    }
    final min = await query.map((row) => row.read(firstCreatedAt)).getSingleOrNull();
    return min?.toDateTime;
  }

  Stream<int> watchUnreadCount({required DateTime? after}) {
    final query = selectOnly(tokenLaunchTable)
      ..addColumns([tokenLaunchTable.eventReference.count()]);
    if (after != null) {
      query.where(tokenLaunchTable.createdAt.isBiggerThanValue(after.microsecondsSinceEpoch));
    }
    return query
        .map((row) => row.read(tokenLaunchTable.eventReference.count()))
        .watchSingle()
        .map((count) => count ?? 0);
  }
}
