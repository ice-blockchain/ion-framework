// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/inputs/search_input/search_input.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/feed_interests.f.dart';
import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/feed/providers/feed_user_interests_provider.r.dart';
import 'package:ion/app/features/feed/providers/recent_topics_notifier.r.dart';
import 'package:ion/app/features/feed/providers/selected_interests_notifier.r.dart';
import 'package:ion/app/features/feed/views/pages/topics_modal/components/recent_topics.dart';
import 'package:ion/app/features/feed/views/pages/topics_modal/hooks/use_sorted_categories.dart';
import 'package:ion/app/features/feed/views/pages/topics_modal/selected_topics.dart';
import 'package:ion/app/features/feed/views/pages/topics_modal/topics_category_section.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class SelectTopicsModal extends HookConsumerWidget {
  const SelectTopicsModal({
    required this.feedType,
    super.key,
  });

  final FeedType feedType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableInterests = ref.watch(feedUserInterestsProvider(feedType)).valueOrNull;

    final sortedCategories =
        useSortedCategories(availableInterests?.categories ?? <String, FeedInterestsCategory>{});

    final availableSubcategories = availableInterests?.subcategories ?? {};
    final selectedSubcategories = ref.watch(
      selectedInterestsNotifierProvider.select(
        (interests) => interests.where(availableSubcategories.containsKey).toSet(),
      ),
    );
    final searchValue = useState('');
    final isAnythingSelected = selectedSubcategories.isNotEmpty;
    final onAdd = useCallback(
      () {
        Navigator.pop(context, false);
        ref
            .read(recentTopicsNotifierProvider(feedType).notifier)
            .appendAll(feedType, selectedSubcategories);
      },
      [selectedSubcategories],
    );

    return SheetContent(
      topPadding: 0,
      bottomPadding: 0,
      bottomBar: const SizedBox.shrink(),
      body: Column(
        children: [
          NavigationAppBar.modal(
            onBackPress: () => Navigator.pop(context, false),
            actions: [
              GestureDetector(
                onTap: isAnythingSelected ? onAdd : null,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0.s),
                  child: Text(
                    '${context.i18n.topics_add}${isAnythingSelected ? ' (${selectedSubcategories.length})' : ''}',
                    style: context.theme.appTextThemes.body.copyWith(
                      color: isAnythingSelected
                          ? context.theme.appColors.primaryAccent
                          : context.theme.appColors.sheetLine,
                    ),
                  ),
                ),
              ),
            ],
            title: Text(context.i18n.topics_title),
          ),
          ScreenSideOffset.small(
            child: SearchInput(
              onTextChanged: (String value) {
                searchValue.value = value;
              },
            ),
          ),
          RecentTopics(
            feedType: feedType,
          ),
          SelectedTopics(
            feedType: feedType,
          ),
          SizedBox(height: 8.0.s),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsetsDirectional.only(
                bottom: MediaQuery.paddingOf(context).bottom,
              ),
              itemCount: sortedCategories.length,
              itemBuilder: (context, index) {
                return TopicsCategorySection(
                  feedType: feedType,
                  category: sortedCategories.entries.elementAt(index),
                  searchQuery: searchValue.value,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
