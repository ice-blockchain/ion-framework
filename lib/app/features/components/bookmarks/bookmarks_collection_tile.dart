// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/list_items_loading_state/item_loading_state.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/components/bookmarks/components/bookmarks_collection_tile_edit_action.dart';
import 'package:ion/app/features/components/bookmarks/components/bookmarks_collection_tile_select_action.dart';
import 'package:ion/app/features/feed/data/models/bookmarks/bookmarks_set.f.dart';
import 'package:ion/app/features/feed/providers/feed_bookmarks_notifier.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/optimistic_ui/features/bookmark/bookmark_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

enum BookmarksCollectionTileMode { select, edit }

class BookmarksCollectionTile extends ConsumerWidget {
  const BookmarksCollectionTile({
    required this.collectionDTag,
    this.eventReference,
    super.key,
  });

  final EventReference? eventReference;
  final String collectionDTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feedBookmarksNotifierProvider(collectionDTag: collectionDTag));
    final entity = state.valueOrNull;
    final isLoading = state.isLoading && entity == null;
    if (isLoading) {
      return const ItemLoadingState();
    }
    if (entity == null) {
      return const SizedBox();
    }
    final isDefaultCollection =
        entity.data.type == BookmarksSetType.homeFeedCollectionsAll.dTagName;
    return ListItem(
      leading: ButtonIconFrame(
        containerSize: 36.0.s,
        color: context.theme.appColors.secondaryBackground,
        borderRadius: BorderRadius.circular(12.0.s),
        border: Border.all(color: context.theme.appColors.onTertiaryFill),
        icon: Assets.svg.iconFolderOpen.icon(color: context.theme.appColors.primaryAccent),
      ),
      title: Text(
        isDefaultCollection ? context.i18n.core_all : entity.data.title,
        style: context.theme.appTextThemes.subtitle2.copyWith(
          color: context.theme.appColors.primaryText,
        ),
      ),
      subtitle: Text(
        entity.data.eventReferences.length.toString(),
        style: context.theme.appTextThemes.caption2.copyWith(
          color: context.theme.appColors.quaternaryText,
        ),
      ),
      onTap: () {
        if (state.isLoading || eventReference == null) return;
        ref.read(toggleBookmarkNotifierProvider.notifier).toggle(
              eventReference: eventReference!,
              collectionDTag: collectionDTag,
            );
      },
      trailing: eventReference != null
          ? BookmarksCollectionTileSelectAction(
              data: entity.data,
              eventReference: eventReference!,
            )
          : BookmarksCollectionTileEditAction(data: entity.data),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 12.0.s),
      backgroundColor: context.theme.appColors.tertiaryBackground,
    );
  }
}
