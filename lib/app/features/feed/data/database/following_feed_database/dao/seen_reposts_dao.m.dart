// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/data/database/following_feed_database/tables/seen_reposts_table.d.dart';
import 'package:ion/app/features/ion_connect/database/event_messages_database.m.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'seen_reposts_dao.m.g.dart';

@DriftAccessor(tables: [SeenRepostsTable])
class SeenRepostsDao extends DatabaseAccessor<EventMessagesDatabase> with _$SeenRepostsDaoMixin {
  SeenRepostsDao({required EventMessagesDatabase db}) : super(db);

  Future<void> insert(SeenRepost repost) async {
    await into(db.seenRepostsTable).insert(repost, mode: InsertMode.insertOrReplace);
  }

  Future<SeenRepost?> getByRepostedReference(EventReference eventReference) {
    return (select(db.seenRepostsTable)
          ..where(
            (tbl) => tbl.repostedEventReference.equalsValue(eventReference),
          ))
        .getSingleOrNull();
  }
}

@Riverpod(keepAlive: true)
SeenRepostsDao seenRepostsDao(Ref ref) =>
    SeenRepostsDao(db: ref.watch(eventMessagesDatabaseProvider));
