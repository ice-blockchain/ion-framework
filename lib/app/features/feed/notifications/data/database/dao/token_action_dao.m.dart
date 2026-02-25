// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/notifications/data/database/notifications_database.m.dart';
import 'package:ion/app/features/feed/notifications/data/database/tables/token_action_table.d.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_action_dao.m.g.dart';

@Riverpod(keepAlive: true)
TokenActionDao tokenActionDao(Ref ref) =>
    TokenActionDao(db: ref.watch(notificationsDatabaseProvider));

@DriftAccessor(tables: [TokenActionTable])
class TokenActionDao extends DatabaseAccessor<NotificationsDatabase> with _$TokenActionDaoMixin {
  TokenActionDao({required NotificationsDatabase db}) : super(db);

  Future<void> insert(TokenAction tokenAction) async {
    await into(db.tokenActionTable).insert(tokenAction, mode: InsertMode.insertOrReplace);
  }

  Future<List<TokenAction>> getTokenActionsAfter({
    required int limit,
    DateTime? after,
  }) async {
    final query = select(tokenActionTable)
      ..orderBy([(t) => OrderingTerm.desc(tokenActionTable.createdAt)])
      ..limit(limit);

    if (after != null) {
      query.where((t) => t.createdAt.isBiggerThanValue(after.microsecondsSinceEpoch));
    }

    return query.get();
  }

  Stream<int> watchUnreadCount({required DateTime? after}) {
    final query = selectOnly(tokenActionTable)
      ..addColumns([tokenActionTable.eventReference.count()]);
    if (after != null) {
      query.where(tokenActionTable.createdAt.isBiggerThanValue(after.microsecondsSinceEpoch));
    }
    return query
        .map((row) => row.read(tokenActionTable.eventReference.count()))
        .watchSingle()
        .map((count) => count ?? 0);
  }
}
