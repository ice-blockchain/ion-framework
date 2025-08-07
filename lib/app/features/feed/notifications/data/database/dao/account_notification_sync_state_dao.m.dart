// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/notifications/data/database/tables/account_notification_sync_state_table.d.dart';
import 'package:ion/app/features/feed/notifications/data/model/content_type.dart';
import 'package:ion/app/features/ion_connect/database/event_messages_database.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_notification_sync_state_dao.m.g.dart';

@Riverpod(keepAlive: true)
AccountNotificationSyncStateDao accountNotificationSyncStateDao(Ref ref) =>
    AccountNotificationSyncStateDao(ref.watch(eventMessagesDatabaseProvider));

@DriftAccessor(tables: [AccountNotificationSyncStateTable])
class AccountNotificationSyncStateDao extends DatabaseAccessor<EventMessagesDatabase>
    with _$AccountNotificationSyncStateDaoMixin {
  AccountNotificationSyncStateDao(super.db);

  Future<void> insertOrUpdate({
    required ContentType contentType,
    required int lastSyncTimestamp,
    int? sinceTimestamp,
  }) {
    return into(accountNotificationSyncStateTable).insertOnConflictUpdate(
      AccountNotificationSyncState(
        contentType: contentType,
        lastSyncTimestamp: lastSyncTimestamp,
        sinceTimestamp: sinceTimestamp,
      ),
    );
  }

  Future<AccountNotificationSyncState?> getByContentType({
    required ContentType contentType,
  }) {
    return (select(accountNotificationSyncStateTable)
          ..where((t) => t.contentType.equalsValue(contentType)))
        .getSingleOrNull();
  }

  Future<DateTime?> getLastSyncTime() async {
    final query = select(accountNotificationSyncStateTable)
      ..orderBy([(t) => OrderingTerm.desc(t.lastSyncTimestamp)])
      ..limit(1);

    final result = await query.getSingleOrNull();
    return result?.lastSyncTimestamp != null
        ? DateTime.fromMicrosecondsSinceEpoch(result!.lastSyncTimestamp)
        : null;
  }
}
