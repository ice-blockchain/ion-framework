// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/notifications/data/database/notifications_database.m.dart';
import 'package:ion/app/features/feed/notifications/data/database/tables/token_updates_table.d.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_updates_dao.m.g.dart';

@Riverpod(keepAlive: true)
TokenUpdatesDao tokenUpdatesDao(Ref ref) =>
    TokenUpdatesDao(db: ref.watch(notificationsDatabaseProvider));

@DriftAccessor(tables: [TokenUpdatesTable])
class TokenUpdatesDao extends DatabaseAccessor<NotificationsDatabase> with _$TokenUpdatesDaoMixin {
  TokenUpdatesDao({required NotificationsDatabase db}) : super(db);

  Future<void> insert(TokenUpdate tokenUpdate) async {
    await into(db.tokenUpdatesTable).insert(tokenUpdate, mode: InsertMode.insertOrReplace);
  }

  Future<List<TokenUpdate>> getTokenUpdatesAfter({
    required int limit,
    DateTime? after,
  }) async {
    final query = select(tokenUpdatesTable)
      ..orderBy([(t) => OrderingTerm.desc(tokenUpdatesTable.createdAt)])
      ..limit(limit);

    if (after != null) {
      query.where((t) => t.createdAt.isBiggerThanValue(after.microsecondsSinceEpoch));
    }

    return query.get();
  }

  Stream<int> watchUnreadCount({required DateTime? after}) {
    final query = selectOnly(tokenUpdatesTable)..addColumns([tokenUpdatesTable.id.count()]);
    if (after != null) {
      query.where(tokenUpdatesTable.createdAt.isBiggerThanValue(after.microsecondsSinceEpoch));
    }
    return query
        .map((row) => row.read(tokenUpdatesTable.id.count()))
        .watchSingle()
        .map((count) => count ?? 0);
  }
}
