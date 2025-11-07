// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/empty_list/empty_list.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/features/components/entities_list/entities_list.dart';
import 'package:ion/app/features/components/entities_list/entities_list_skeleton.dart';
import 'package:ion/app/features/components/entities_list/entity_list_item.f.dart';
import 'package:ion/app/features/feed/data/models/bookmarks/bookmarks_set.f.dart';
import 'package:ion/app/features/feed/providers/feed_bookmarks_notifier.r.dart';
import 'package:ion/app/features/user/pages/bookmarks_page/components/bookmarks_filters.dart';
import 'package:ion/app/features/user/pages/bookmarks_page/components/bookmarks_header.dart';
import 'package:ion/app/utils/future.dart';
import 'package:ion/generated/assets.gen.dart';

class BookmarksPage extends HookConsumerWidget {
  const BookmarksPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCollectionDTag = useState(BookmarksSetType.homeFeedCollectionsAll.dTagName);
    final rawQuery = useState<String>('');
    final keyword = useDebounced(rawQuery.value, 300.milliseconds) ?? '';
    final collectionEntityState = ref.watch(
      filteredBookmarksRefsProvider(
        keyword: keyword,
        collectionDTag: selectedCollectionDTag.value,
      ),
    );

    return Scaffold(
      appBar: BookmarksHeader(
        loading: collectionEntityState.isLoading && rawQuery.value.isNotEmpty,
        onSearchQueryUpdated: (value) => rawQuery.value = value.trim(),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: BookmarksFilters(
              activeCollectionDTag: selectedCollectionDTag.value,
              onFilterTap: (collectionDTag) => selectedCollectionDTag.value = collectionDTag,
            ),
          ),
          const SliverToBoxAdapter(child: SectionSeparator()),
          ...collectionEntityState.when(
            data: (refs) {
              if (refs.isEmpty) {
                return [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyList(
                      asset: Assets.svg.walletIconEmptybookmraks,
                      title: context.i18n.bookmarks_empty_state,
                    ),
                  ),
                ];
              } else {
                return [
                  EntitiesList(
                    items: refs.map((ref) => IonEntityListItem.event(eventReference: ref)).toList(),
                    network: true,
                  ),
                ];
              }
            },
            error: (error, stackTrace) => [const SliverFillRemaining(child: SizedBox())],
            loading: () => [const EntitiesListSkeleton()],
          ),
        ],
      ),
    );
  }
}
