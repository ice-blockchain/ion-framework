// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/inputs/search_input/search_input.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/feed/providers/feed_selected_visible_article_categories_provider.r.dart';
import 'package:ion/app/features/feed/providers/feed_user_interests_provider.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class FeedVisibleArticleCategoriesModal extends HookConsumerWidget {
  const FeedVisibleArticleCategoriesModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableCategories =
        ref.watch(feedUserInterestsProvider(FeedType.article)).valueOrNull?.categories ?? {};
    final selectedCategories = ref.watch(feedSelectedVisibleArticleCategoriesProvider);
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;
    final searchValue = useState('');
    final localSelectedCategories = useState<Set<String>>(
      Set.from(selectedCategories),
    );

    final filteredCategories = useMemoized(
      () {
        final query = searchValue.value.toLowerCase();
        return availableCategories.entries.where((categoryEntry) {
          final title = categoryEntry.value.display.toLowerCase();
          return title.contains(query);
        }).toList();
      },
      [searchValue.value],
    );

    final envMinCategories = ref
        .watch(envProvider.notifier)
        .get<int>(EnvVariable.FEED_MIN_VISIBLE_ARTICLE_CATEGORIES_NUMBER);
    final minCategories = min(envMinCategories, availableCategories.length);

    return SheetContent(
      topPadding: 0,
      body: Column(
        children: [
          NavigationAppBar.modal(
            onBackPress: () => Navigator.pop(context, false),
            actions: [
              if (localSelectedCategories.value.length >= minCategories)
                GestureDetector(
                  onTap: () {
                    ref.read(feedSelectedVisibleArticleCategoriesProvider.notifier).categories =
                        localSelectedCategories.value.toSet();
                    Navigator.pop(context, false);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0.s),
                    child: Text(
                      '${context.i18n.topics_add} (${localSelectedCategories.value.length})',
                      style: context.theme.appTextThemes.body.copyWith(
                        color: context.theme.appColors.primaryAccent,
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0.s),
                  child: Text(
                    context.i18n.feed_article_categories_add_min(minCategories),
                    style: context.theme.appTextThemes.body.copyWith(
                      color: context.theme.appColors.tertiaryText,
                    ),
                  ),
                ),
            ],
            title: Text(context.i18n.topics_title),
          ),
          ScreenSideOffset.small(
            child: SearchInput(
              restorationId: 'feed_article_categories_search_input',
              onTextChanged: (String value) {
                searchValue.value = value;
              },
            ),
          ),
          SizedBox(height: 8.0.s),
          Expanded(
            child: ListView.builder(
              restorationId: 'feed_visible_article_categories_scroll',
              itemCount: filteredCategories.length,
              itemBuilder: (BuildContext context, int index) {
                final subcategory = filteredCategories[index];
                final isSelected = localSelectedCategories.value.contains(subcategory.key);

                return ListItem(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 8.0.s),
                  constraints: const BoxConstraints(),
                  onTap: () => _toggleTopicSelection(ref, subcategory.key, localSelectedCategories),
                  backgroundColor: colors.secondaryBackground,
                  trailing: isSelected
                      ? Assets.svg.iconBlockCheckboxOnblue.icon(color: colors.success)
                      : Assets.svg.iconBlockCheckboxOff.icon(color: colors.tertiaryText),
                  title: Text(subcategory.value.display, style: textStyles.body),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _toggleTopicSelection(
    WidgetRef ref,
    String subcategoryKey,
    ValueNotifier<Set<String>> selectedInterestsNotifier,
  ) {
    if (selectedInterestsNotifier.value.contains(subcategoryKey)) {
      selectedInterestsNotifier.value = Set.from(selectedInterestsNotifier.value)
        ..remove(subcategoryKey);
    } else {
      selectedInterestsNotifier.value = Set.from(selectedInterestsNotifier.value)
        ..add(subcategoryKey);
    }
  }
}
