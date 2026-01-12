// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/bottom_sheet_menu/bottom_sheet_menu_content.dart';
import 'package:ion/app/components/icons/outlined_icon.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/bookmarks/bookmarks_set.f.dart';
import 'package:ion/app/features/feed/providers/feed_bookmarks_notifier.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';
import 'package:ion/app/features/optimistic_ui/features/bookmark/bookmark_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

enum BookmarkButtonMode {
  menuItem,
  menuContent,
  iconButton,
}

class BookmarkButton extends HookConsumerWidget {
  const BookmarkButton({
    this.eventReference,
    this.mode = BookmarkButtonMode.menuItem,
    this.collectionDTag,
    this.iconSize,
    this.iconColor,
    super.key,
  });

  final EventReference? eventReference;
  final BookmarkButtonMode mode;
  final String? collectionDTag;
  final double? iconSize;
  final Color? iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveCollectionDTag =
        collectionDTag ?? BookmarksSetType.homeFeedCollectionsAll.dTagName;

    ref.displayErrors(
      feedBookmarksNotifierProvider(collectionDTag: effectiveCollectionDTag),
    );
    final bookmarkState = ref.watch(
      feedBookmarksNotifierProvider(collectionDTag: effectiveCollectionDTag),
    );
    final isLoading = bookmarkState.isLoading;
    final isBookmarked = eventReference != null &&
        ref.watch(
          isBookmarkedInCollectionProvider(
            eventReference!,
            collectionDTag: effectiveCollectionDTag,
          ),
        );

    useEffect(
      () {
        // sync to DB if bookmarked from cache only
        if (isBookmarked && eventReference != null) {
          ref
              .read(ionConnectDatabaseCacheProvider.notifier)
              .saveEventReference(eventReference!, network: false);
        }
        return null;
      },
      [isBookmarked],
    );

    final iconAsset = isBookmarked
        ? mode == BookmarkButtonMode.iconButton
            ? Assets.svg.iconBookmarksOn
            : Assets.svg.iconUnbookmarks
        : Assets.svg.iconBookmarks;
    final label = isBookmarked ? context.i18n.button_unbookmark : context.i18n.button_bookmark;

    return switch (mode) {
      BookmarkButtonMode.menuItem => ListItem(
          onTap: isLoading ? null : () => _handleTap(ref, isBookmarked, effectiveCollectionDTag),
          leading: OutlinedIcon(
            icon: iconAsset.icon(
              size: 20.0.s,
              color: context.theme.appColors.primaryAccent,
            ),
          ),
          title: Text(label),
          backgroundColor: Colors.transparent,
        ),
      BookmarkButtonMode.menuContent => BottomSheetMenuContent(
          groups: [
            [
              ListItem(
                onTap:
                    isLoading ? null : () => _handleTap(ref, isBookmarked, effectiveCollectionDTag),
                leading: OutlinedIcon(
                  icon: iconAsset.icon(
                    size: 20.0.s,
                    color: context.theme.appColors.primaryAccent,
                  ),
                ),
                title: Text(label),
                backgroundColor: Colors.transparent,
              ),
            ],
          ],
        ),
      BookmarkButtonMode.iconButton => IconButton(
          padding: EdgeInsets.zero,
          onPressed:
              isLoading ? null : () => _handleTap(ref, isBookmarked, effectiveCollectionDTag),
          icon: iconAsset.icon(
            size: iconSize ?? 24.s,
            color: iconColor ?? context.theme.appColors.onPrimaryAccent,
          ),
        ),
    };
  }

  void _handleTap(
    WidgetRef ref,
    bool isBookmarked,
    String effectiveCollectionDTag,
  ) {
    if (eventReference == null) return;
    if (mode == BookmarkButtonMode.menuItem || mode == BookmarkButtonMode.menuContent) {
      Navigator.of(ref.context).pop();
    }
    ref.read(toggleBookmarkNotifierProvider.notifier).toggle(
          eventReference: eventReference!,
          collectionDTag: effectiveCollectionDTag,
        );
    if (!isBookmarked && mode != BookmarkButtonMode.menuContent) {
      AddBookmarkRoute(eventReference: eventReference!.encode()).push<void>(ref.context);
    }
  }
}
