// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/providers/feed_bookmarks_notifier.r.dart';
import 'package:ion/app/features/user/pages/bookmarks_page/components/bookmarks_filter_tile.dart';

class BookmarksFilters extends HookConsumerWidget {
  const BookmarksFilters({
    required this.activeCollectionDTag,
    required this.onFilterTap,
    super.key,
  });

  final String activeCollectionDTag;
  final void Function(String collectionDTag) onFilterTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsRefs = ref.watch(feedBookmarkCollectionsNotifierProvider).valueOrNull ?? [];
    final collectionsDTags =
        collectionsRefs.map((collectionRef) => collectionRef.dTag).whereType<String>().toList();
    return SizedBox(
      height: 64.0.s,
      child: ListView.separated(
        restorationId: 'user_bookmarks_filters_scroll',
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 12.0.s),
        itemCount: collectionsDTags.length,
        itemBuilder: (context, index) {
          final collectionDTag = collectionsDTags[index];
          return BookmarksFilterTile(
            collectionDTag: collectionDTag,
            isActive: collectionDTag == activeCollectionDTag,
            onTap: () => onFilterTap(collectionDTag),
          );
        },
        separatorBuilder: (_, __) => SizedBox(
          width: 12.0.s,
        ),
      ),
    );
  }
}
