// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/counter_items_footer/text_action_button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/bookmarks/bookmarks_set.f.dart';
import 'package:ion/app/features/feed/providers/feed_bookmarks_notifier.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';
import 'package:ion/app/features/optimistic_ui/features/bookmark/bookmark_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class BookmarkButton extends HookConsumerWidget {
  const BookmarkButton({
    required this.eventReference,
    this.size,
    this.color,
    this.padding,
    super.key,
  });

  final EventReference eventReference;
  final double? size;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkState = ref.watch(
      feedBookmarksNotifierProvider(
        collectionDTag: BookmarksSetType.homeFeedCollectionsAll.dTagName,
      ),
    );
    final isLoading = bookmarkState.isLoading;
    final isBookmarked = ref.watch(
      isBookmarkedInCollectionProvider(
        eventReference,
        collectionDTag: BookmarksSetType.homeFeedCollectionsAll.dTagName,
      ),
    );

    useEffect(
      () {
        // sync to DB if bookmarked from cache only
        if (isBookmarked) {
          ref
              .read(ionConnectDatabaseCacheProvider.notifier)
              .saveEventReference(eventReference, network: false);
        }
        return null;
      },
      [isBookmarked],
    );

    ref.displayErrors(
      feedBookmarksNotifierProvider(
        collectionDTag: BookmarksSetType.homeFeedCollectionsAll.dTagName,
      ),
    );

    return GestureDetector(
      onTap: isLoading
          ? null
          : () {
              ref.read(toggleBookmarkNotifierProvider.notifier).toggle(
                    eventReference: eventReference,
                    collectionDTag: BookmarksSetType.homeFeedCollectionsAll.dTagName,
                  );
              if (!isBookmarked) {
                AddBookmarkRoute(eventReference: eventReference.encode()).push<void>(context);
              }
            },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Center(
          child: TextActionButton(
            icon: isBookmarked
                ? Assets.svg.iconBookmarksOn.icon(size: size)
                : Assets.svg.iconBookmarks.icon(size: size, color: color),
            textColor: color ?? context.theme.appColors.onTertiaryBackground,
          ),
        ),
      ),
    );
  }
}
