// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/optimistic_ui/database/optimistic_ui_database.m.dart';
import 'package:ion/app/features/optimistic_ui/database/tables/user_sent_likes_table.d.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_sent_likes_dao.m.g.dart';

@Riverpod(keepAlive: true)
UserSentLikesDao userSentLikesDao(Ref ref) => UserSentLikesDao(
      db: ref.watch(optimisticUiDatabaseProvider),
    );

@DriftAccessor(tables: [UserSentLikesTable])
class UserSentLikesDao extends DatabaseAccessor<OptimisticUiDatabase> with _$UserSentLikesDaoMixin {
  UserSentLikesDao({required OptimisticUiDatabase db}) : super(db);

  Future<bool> hasUserLiked(EventReference eventReference) async {
    final query = select(db.userSentLikesTable)
      ..where((tbl) => tbl.eventReference.equals(eventReference.toString()));
    final result = await query.getSingleOrNull();
    return result != null;
  }

  Future<UserSentLike?> getUserLike(EventReference eventReference) async {
    final query = select(db.userSentLikesTable)
      ..where((tbl) => tbl.eventReference.equals(eventReference.toString()));
    return query.getSingleOrNull();
  }

  Future<void> insertOrUpdateLike({
    required EventReference eventReference,
    required String status,
    DateTime? sentAt,
  }) async {
    final now = sentAt ?? DateTime.now();
    final like = UserSentLike(
      eventReference: eventReference,
      sentAt: now.microsecondsSinceEpoch,
      status: status,
    );
    await into(db.userSentLikesTable).insert(
      like,
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> updateLikeStatus({
    required EventReference eventReference,
    required String status,
  }) async {
    await (update(db.userSentLikesTable)
          ..where((tbl) => tbl.eventReference.equals(eventReference.toString())))
        .write(
      UserSentLikesTableCompanion(
        status: Value(status),
      ),
    );
  }

  Future<void> deleteLike(EventReference eventReference) async {
    await (delete(db.userSentLikesTable)
          ..where((tbl) => tbl.eventReference.equals(eventReference.toString())))
        .go();
  }

  Future<List<UserSentLike>> getPendingLikes() async {
    final query = select(db.userSentLikesTable)..where((tbl) => tbl.status.equals('pending'));
    return query.get();
  }
}
