// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/inputs/search_input/search_input.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/separated/separated_column.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/providers/recent_emoji_reactions_provider.r.dart';
import 'package:ion/app/features/chat/views/components/message_items/components.dart';
import 'package:ion/app/features/core/model/emoji/emoji_category.dart';
import 'package:ion/app/features/core/model/emoji/emoji_group.f.dart';
import 'package:ion/app/features/core/providers/emoji/emoji_set_provider.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:visibility_detector/visibility_detector.dart';

part 'components/emoji_category_button.dart';
part 'components/emojis_grid_view.dart';

class SearchEmojiModal extends HookConsumerWidget {
  const SearchEmojiModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emojiGroups = ref.watch(emojisFilteredByQueryProvider);
    final recentEmojiReactions = ref.read(recentEmojiReactionsProvider);
    final activeCategory = useState<EmojiCategory>(EmojiCategory.recent);

    final categoryKeys = useMemoized(
      () => EmojiCategory.values.map((category) => GlobalKey()).toList(),
      [],
    );

    final hasLoadedEmojis = useMemoized(
      () => emojiGroups.hasValue && emojiGroups.value!.isNotEmpty,
      [emojiGroups],
    );

    return SheetContent(
      body: ScreenSideOffset.small(
        child: Column(
          children: [
            NavigationAppBar.modal(
              title: const Text('Emoji'),
              showBackButton: false,
              actions: [
                NavigationCloseButton(
                  onPressed: () {
                    context.pop();
                  },
                ),
              ],
            ),
            _EmojiCategoryButtons(categoryKeys: categoryKeys, activeCategory: activeCategory),
            SearchInput(
              restorationId: 'search_emoji_search_input',
              onTextChanged: (value) {
                ref.read(emojiSearchQueryProvider.notifier).query = value;
              },
            ),
            if (hasLoadedEmojis)
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsetsDirectional.only(top: 16.0.s, bottom: 10.0.s),
                  child: SeparatedColumn(
                    separator: SizedBox(height: 24.0.s),
                    children: EmojiCategory.values.map((category) {
                      final emojis = _getEmojisByCategory(
                        category,
                        recentEmojiReactions,
                        emojiGroups.value!,
                      );

                      if (emojis.isEmpty) {
                        return const SizedBox();
                      }

                      return VisibilityDetector(
                        key: categoryKeys[category.index],
                        onVisibilityChanged: (visibility) {
                          if (context.mounted) {
                            _handleCategoryVisibilityChange(
                              category,
                              visibility.visibleFraction,
                              activeCategory,
                            );
                          }
                        },
                        child: _EmojisGridView(
                          emojis: emojis,
                          title: category.getTitle(context),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              )
            else
              const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }

  void _handleCategoryVisibilityChange(
    EmojiCategory category,
    double visibleFraction,
    ValueNotifier<EmojiCategory> activeCategory,
  ) {
    if (activeCategory.value == EmojiCategory.recent) {
      if (category == EmojiCategory.recent && visibleFraction == 0) {
        activeCategory.value = EmojiCategory.smileysPeople;
      }
      return;
    }
    if (visibleFraction > 0) {
      activeCategory.value = category;
    }
  }

  List<String> _getEmojisByCategory(
    EmojiCategory category,
    List<String> recentEmojiReactions,
    List<EmojiGroup> emojiGroups,
  ) {
    List<String> emojis;

    if (category == EmojiCategory.recent) {
      emojis = recentEmojiReactions;
    } else {
      emojis = emojiGroups
              .firstWhereOrNull(
                (group) => group.slug == category.getSlug(),
              )
              ?.emojis
              .map((emoji) => emoji.emoji)
              .toList() ??
          [];
    }
    return emojis;
  }
}

class _EmojiCategoryButtons extends StatelessWidget {
  const _EmojiCategoryButtons({
    required this.categoryKeys,
    required this.activeCategory,
  });

  final List<GlobalKey<State<StatefulWidget>>> categoryKeys;
  final ValueNotifier<EmojiCategory> activeCategory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(top: 16.0.s, bottom: 12.0.s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: EmojiCategory.values.map((category) {
          return _EmojiCategoryButton(
            category: category,
            onPressed: () {
              final key = categoryKeys[category.index];
              final widgetContext = key.currentContext;

              if (widgetContext != null) {
                Scrollable.ensureVisible(widgetContext);
                activeCategory.value = category;
              }
            },
            isActive: activeCategory.value == category,
          );
        }).toList(),
      ),
    );
  }
}
