// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/database/event_messages_database.m.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user_block/model/database/tables/unblock_event_table.d.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'unblock_event_dao.m.g.dart';

@riverpod
UnblockEventDao unblockEventDao(Ref ref) {
  keepAliveWhenAuthenticated(ref);
  return UnblockEventDao(ref.watch(eventMessagesDatabaseProvider));
}

@DriftAccessor(tables: [UnblockEventTable])
class UnblockEventDao extends DatabaseAccessor<EventMessagesDatabase> with _$UnblockEventDaoMixin {
  UnblockEventDao(super.db);

  Future<void> add(EventReference eventReference) async {
    await into(db.unblockEventTable).insert(
      UnblockEventTableCompanion(eventReference: Value(eventReference)),
      mode: InsertMode.insertOrReplace,
    );
  }
}
