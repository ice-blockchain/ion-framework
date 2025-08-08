// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/providers/feed_bookmarks_notifier.r.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_sync_strategy.dart';
import 'package:ion/app/features/optimistic_ui/features/bookmark/bookmark_sync_strategy.dart';
import 'package:ion/app/features/optimistic_ui/features/bookmark/model/bookmark.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bookmark_sync_strategy_provider.r.g.dart';

@riverpod
SyncStrategy<Bookmark> bookmarkSyncStrategy(Ref ref) {
  return BookmarkSyncStrategy(
    toggleBookmark: (bookmark) async {
      await ref
          .read(feedBookmarksNotifierProvider(collectionDTag: bookmark.collectionDTag).notifier)
          .toggleBookmark(bookmark.eventReference);
    },
  );
}
