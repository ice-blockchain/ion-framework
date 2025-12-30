// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/notifications/data/database/notifications_database.m.dart';
import 'package:ion/app/features/feed/notifications/data/database/tables/mentions_table.d.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mentions_dao.m.g.dart';

@Riverpod(keepAlive: true)
MentionsDao mentionsDao(Ref ref) => MentionsDao(db: ref.watch(notificationsDatabaseProvider));

@DriftAccessor(tables: [MentionsTable])
class MentionsDao extends DatabaseAccessor<NotificationsDatabase> with _$MentionsDaoMixin {
  MentionsDao({required NotificationsDatabase db}) : super(db);

  Future<void> insert(Mention mention) async {
    await into(db.mentionsTable).insert(mention, mode: InsertMode.insertOrReplace);
  }

  Future<List<Mention>> getMentionsAfter({
    required int limit,
    DateTime? after,
  }) async {
    final query = select(mentionsTable)
      ..orderBy([(t) => OrderingTerm.desc(mentionsTable.createdAt)])
      ..limit(limit);

    if (after != null) {
      query.where((t) => t.createdAt.isBiggerThanValue(after.microsecondsSinceEpoch));
    }

    return query.get();
  }

  Stream<int> watchUnreadCount({required DateTime? after}) {
    final query = selectOnly(mentionsTable)..addColumns([mentionsTable.eventReference.count()]);
    if (after != null) {
      query.where(mentionsTable.createdAt.isBiggerThanValue(after.microsecondsSinceEpoch));
    }
    return query
        .map((row) => row.read(mentionsTable.eventReference.count()))
        .watchSingle()
        .map((count) => count ?? 0);
  }
}
