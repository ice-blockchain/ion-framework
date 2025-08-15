// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/feed/data/repository/following_feed_seen_events_repository.r.dart';
import 'package:ion/app/features/feed/providers/feed_posts_provider.r.dart';
import 'package:ion/app/features/feed/providers/feed_selected_article_categories_provider.r.dart';
import 'package:ion/app/features/feed/providers/feed_selected_visible_article_categories_provider.r.dart';
import 'package:ion/app/features/feed/providers/feed_user_interests_provider.r.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/article_categories_menu/article_categories_row.dart';

class ArticleCategoriesMenu extends HookConsumerWidget {
  const ArticleCategoriesMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableCategories = ref.watch(
      feedUserInterestsProvider(FeedType.article)
          .select((state) => state.valueOrNull?.categories ?? {}),
    );
    final visibleCategoriesKeys = ref.watch(feedSelectedVisibleArticleCategoriesProvider);
    final selectedCategoriesKeys = ref.watch(feedSelectedArticleCategoriesProvider);
    var visibleSubcategories = availableCategories.entries
        .where(
          (categoryEntry) => visibleCategoriesKeys.contains(categoryEntry.key),
        )
        .toList();

    if (visibleSubcategories.isEmpty) {
      visibleSubcategories = availableCategories.entries.toList();
    }

    final firstRowItemCount = (visibleSubcategories.length / 2).ceil();
    final firstRowItems = visibleSubcategories.sublist(0, firstRowItemCount);
    final secondRowItems = visibleSubcategories.sublist(firstRowItemCount);

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: EdgeInsetsDirectional.only(bottom: 12.0.s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 16.0.s),
                ArticleCategoriesRow(
                  items: firstRowItems,
                  selectedItems: selectedCategoriesKeys,
                  onToggle: (String categoryKey) => _toggleCategory(ref, categoryKey),
                  showAddButton: true,
                ),
                SizedBox(height: 10.0.s),
                ArticleCategoriesRow(
                  items: secondRowItems,
                  selectedItems: selectedCategoriesKeys,
                  onToggle: (String categoryKey) => _toggleCategory(ref, categoryKey),
                ),
              ],
            ),
          ),
        ),
        const SectionSeparator(),
      ],
    );
  }

  Future<void> _toggleCategory(WidgetRef ref, String categoryKey) async {
    final selectedSubcategoriesKeys = ref.read(feedSelectedArticleCategoriesProvider);
    final newCategories = selectedSubcategoriesKeys.toSet();
    if (newCategories.contains(categoryKey)) {
      newCategories.remove(categoryKey);
    } else {
      newCategories.add(categoryKey);
    }
    ref.read(feedSelectedArticleCategoriesProvider.notifier).categories = newCategories;
    await ref
        .read(followingFeedSeenEventsRepositoryProvider)
        .deleteEvents(feedType: FeedType.article);
    ref.read(feedPostsProvider.notifier).refresh();
  }
}
