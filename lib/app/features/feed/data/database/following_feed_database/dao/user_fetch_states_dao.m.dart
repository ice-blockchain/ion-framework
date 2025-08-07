// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/data/database/following_feed_database/converters/feed_modifier_converter.d.dart';
import 'package:ion/app/features/feed/data/database/following_feed_database/tables/user_fetch_states_table.d.dart';
import 'package:ion/app/features/feed/data/models/feed_modifier.dart';
import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/ion_connect/database/event_messages_database.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_fetch_states_dao.m.g.dart';

@DriftAccessor(tables: [UserFetchStatesTable])
class UserFetchStatesDao extends DatabaseAccessor<EventMessagesDatabase>
    with _$UserFetchStatesDaoMixin {
  UserFetchStatesDao({required EventMessagesDatabase db}) : super(db);

  Future<void> insertOrUpdate(
    String pubkey, {
    required FeedType feedType,
    required bool hasContent,
    FeedModifier? feedModifier,
  }) async {
    await into(userFetchStatesTable).insert(
      UserFetchStatesTableCompanion.insert(
        feedType: feedType,
        feedModifier: feedModifier,
        pubkey: pubkey,
        emptyFetchCount: hasContent ? 0 : 1,
        lastFetchTime: DateTime.now().microsecondsSinceEpoch,
      ),
      onConflict: DoUpdate(
        (old) => UserFetchStatesTableCompanion.custom(
          feedType: old.feedType,
          feedModifier: old.feedModifier,
          pubkey: old.pubkey,
          emptyFetchCount: hasContent ? const Constant(0) : old.emptyFetchCount + const Constant(1),
          lastFetchTime: Constant(DateTime.now().microsecondsSinceEpoch),
        ),
      ),
    );
  }

  Future<List<FollowingUserFetchState>> selectAll({
    required List<String> pubkeys,
    required FeedType feedType,
    FeedModifier? feedModifier,
  }) {
    final query = select(userFetchStatesTable)
      ..where((tbl) => tbl.pubkey.isIn(pubkeys))
      ..where((tbl) => tbl.feedType.equalsValue(feedType))
      ..where(
        // `FeedModifierConverter` should be used manually here,
        // because otherwise there is a false positive issue that it throws an exception that we're trying
        // to pass a null value to a non-nullable column, even though `FeedModifierConverter().toSql`
        // returns non-nullable int.
        (tbl) => tbl.feedModifier.equals(const FeedModifierConverter().toSql(feedModifier)),
      );
    return query.get();
  }
}

@Riverpod(keepAlive: true)
UserFetchStatesDao userFetchStatesDao(Ref ref) =>
    UserFetchStatesDao(db: ref.watch(eventMessagesDatabaseProvider));
