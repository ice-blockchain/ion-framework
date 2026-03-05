// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_items_loading_state/list_items_loading_state.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/bookmarks/bookmarks_collection_tile.dart';
import 'package:ion/app/features/components/bookmarks/new_bookmarks_collection_button.dart';
import 'package:ion/app/features/feed/data/models/bookmarks/bookmarks_set.f.dart';
import 'package:ion/app/features/feed/providers/feed_bookmarks_notifier.r.dart';
import 'package:ion/app/features/user/pages/edit_bookmarks_page/components/edit_bookmarks_header.dart';

class EditBookmarksPage extends HookConsumerWidget {
  const EditBookmarksPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksCollections = ref.watch(feedBookmarkCollectionsNotifierProvider);
    return Scaffold(
      appBar: const EditBookmarksHeader(),
      body: ScreenSideOffset.small(
        child: CustomScrollView(
          restorationId: 'user_edit_bookmarks_scroll',
          slivers: bookmarksCollections.when(
            data: (data) {
              final collectionsDTags = data
                  .map((eventReference) => eventReference.dTag)
                  .whereType<String>()
                  .where((dTag) => dTag != BookmarksSetType.homeFeedCollectionsAll.dTagName)
                  .toList();
              return [
                SliverList.separated(
                  itemCount: collectionsDTags.length,
                  separatorBuilder: (BuildContext context, int index) => SizedBox(height: 16.0.s),
                  itemBuilder: (BuildContext context, int index) {
                    return BookmarksCollectionTile(
                      collectionDTag: collectionsDTags[index],
                    );
                  },
                ),
                const SliverToBoxAdapter(
                  child: NewBookmarksCollectionButton(),
                ),
              ];
            },
            error: (error, stackTrace) => [const SliverFillRemaining(child: SizedBox())],
            loading: () => [
              ListItemsLoadingState(
                itemHeight: 60.0.s,
                listItemsLoadingStateType: ListItemsLoadingStateType.scrollView,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
