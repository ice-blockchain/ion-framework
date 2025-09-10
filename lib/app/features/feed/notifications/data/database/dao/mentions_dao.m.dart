// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
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

  Future<List<Mention>> getAll() async {
    return (select(mentionsTable)..orderBy([(t) => OrderingTerm.desc(mentionsTable.createdAt)]))
        .get();
  }

  Future<DateTime?> getLastCreatedAt() async {
    final maxCreatedAt = mentionsTable.createdAt.max();
    final max = await (selectOnly(mentionsTable)..addColumns([maxCreatedAt]))
        .map((row) => row.read(maxCreatedAt))
        .getSingleOrNull();
    return max?.toDateTime;
  }

  Future<DateTime?> getFirstCreatedAt({DateTime? after}) async {
    final firstCreatedAt = mentionsTable.createdAt.min();
    final query = selectOnly(mentionsTable)..addColumns([firstCreatedAt]);
    if (after != null) {
      query.where(mentionsTable.createdAt.isBiggerThanValue(after.microsecondsSinceEpoch));
    }
    final min = await query.map((row) => row.read(firstCreatedAt)).getSingleOrNull();
    return min?.toDateTime;
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
