// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu_container.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/feed_category.dart';
import 'package:ion/app/features/feed/data/models/feed_filter.dart';
import 'package:ion/app/features/feed/providers/feed_current_filter_provider.m.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/feed_controls/components/feed_filters/feed_filters_menu_item.dart';

class FeedFiltersMenuOverlay extends StatelessWidget {
  const FeedFiltersMenuOverlay({
    required this.closeMenu,
    this.scrollController,
    super.key,
  });

  final VoidCallback closeMenu;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return OverlayMenuContainer(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 200.0.s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16.0.s),
            ...<Widget>[
              for (final category in FeedCategory.values)
                _FeedCategoryItem(
                  category: category,
                  closeMenu: closeMenu,
                ),
            ].separated(SizedBox(height: 10.0.s)),
            SizedBox(height: 10.0.s),
            const HorizontalSeparator(),
            SizedBox(height: 10.0.s),
            ...<Widget>[
              for (final filter in FeedFilter.values)
                _FeedFilterItem(
                  filter: filter,
                  closeMenu: closeMenu,
                ),
            ].separated(SizedBox(height: 10.0.s)),
            SizedBox(height: 16.0.s),
          ],
        ),
      ),
    );
  }
}

class _FeedCategoryItem extends ConsumerWidget {
  const _FeedCategoryItem({
    required this.category,
    required this.closeMenu,
  });

  final FeedCategory category;
  final VoidCallback closeMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCategory = ref.watch(feedCurrentFilterProvider.select((state) => state.category));
    final isSelected = currentCategory == category;

    return FeedFiltersMenuItem(
      onPressed: () {
        ref.read(feedCurrentFilterProvider.notifier).category = category;
        closeMenu();
      },
      isSelected: isSelected,
      icon: ButtonIconFrame(
        color: category.getColor(context),
        icon: category.getIcon(context),
      ),
      label: category.getLabel(context),
    );
  }
}

class _FeedFilterItem extends ConsumerWidget {
  const _FeedFilterItem({
    required this.filter,
    required this.closeMenu,
  });

  final FeedFilter filter;
  final VoidCallback closeMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;
    final currentFilter = ref.watch(feedCurrentFilterProvider.select((state) => state.filter));
    final isSelected = currentFilter == filter;

    return FeedFiltersMenuItem(
      onPressed: () {
        ref.read(feedCurrentFilterProvider.notifier).filter = filter;
        closeMenu();
      },
      isSelected: isSelected,
      icon: ButtonIconFrame(
        color: colors.tertiaryBackground,
        border: Border.all(color: colors.onTertiaryFill),
        icon: filter.getIcon(context),
      ),
      label: filter.getLabel(context),
    );
  }
}
