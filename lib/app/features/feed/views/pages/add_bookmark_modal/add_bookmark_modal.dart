// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_items_loading_state/list_items_loading_state.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/features/components/bookmarks/bookmarks_collection_tile.dart';
import 'package:ion/app/features/components/bookmarks/new_bookmarks_collection_button.dart';
import 'package:ion/app/features/feed/data/models/bookmarks/bookmarks_set.f.dart';
import 'package:ion/app/features/feed/providers/feed_bookmarks_notifier.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class AddBookmarkModal extends ConsumerWidget {
  const AddBookmarkModal({
    required this.eventReference,
    super.key,
  });

  final EventReference eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksCollections = ref.watch(feedBookmarkCollectionsNotifierProvider);

    return SheetContent(
      bottomPadding: 0,
      body: ScreenSideOffset.small(
        child: bookmarksCollections.when(
          data: (data) {
            final collectionsDTags = data
                .map((eventReference) => eventReference.dTag)
                .whereType<String>()
                .where((dTag) => dTag != BookmarksSetType.homeFeedCollectionsAll.dTagName)
                .toList();

            return ListView(
              shrinkWrap: collectionsDTags.length < LoadMoreBuilder.shrinkWrapThreshold,
              children: [
                SizedBox(height: 24.0.s),
                BookmarksCollectionTile(
                  eventReference: eventReference,
                  collectionDTag: BookmarksSetType.homeFeedCollectionsAll.dTagName,
                ),
                SizedBox(height: 16.0.s),
                const HorizontalSeparator(),
                if (collectionsDTags.isNotEmpty) SizedBox(height: 16.0.s),
                ...collectionsDTags.map(
                  (dTag) => Padding(
                    padding: EdgeInsetsDirectional.only(bottom: 16.0.s),
                    child: BookmarksCollectionTile(
                      key: ValueKey(dTag),
                      eventReference: eventReference,
                      collectionDTag: dTag,
                    ),
                  ),
                ),
                const NewBookmarksCollectionButton(),
                const ScreenBottomOffset(),
              ],
            );
          },
          error: (error, stackTrace) => const Center(child: SizedBox()),
          loading: () => ListItemsLoadingState(
            itemHeight: 60.0.s,
            itemsCount: 3,
            listItemsLoadingStateType: ListItemsLoadingStateType.listView,
          ),
        ),
      ),
    );
  }
}
