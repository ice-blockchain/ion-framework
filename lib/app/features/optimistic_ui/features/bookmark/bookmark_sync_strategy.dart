// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/optimistic_ui/core/optimistic_sync_strategy.dart';
import 'package:ion/app/features/optimistic_ui/features/bookmark/model/bookmark.f.dart';

class BookmarkSyncStrategy implements SyncStrategy<Bookmark> {
  BookmarkSyncStrategy({
    required this.toggleBookmark,
  });

  final Future<void> Function(Bookmark) toggleBookmark;

  @override
  Future<Bookmark> send(Bookmark previous, Bookmark optimistic) async {
    await toggleBookmark(optimistic);
    return optimistic;
  }
}
