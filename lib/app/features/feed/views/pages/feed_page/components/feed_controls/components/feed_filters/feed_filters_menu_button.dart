// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/providers/feed_current_filter_provider.m.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/feed_controls/components/feed_filters/feed_filters_menu_overlay.dart';

class FeedFiltersMenuButton extends StatelessWidget {
  const FeedFiltersMenuButton({
    this.scrollController,
    super.key,
  });

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return OverlayMenu(
      isNeedHideOnTabChange: true,
      scrollController: scrollController,
      menuBuilder: (closeMenu) => FeedFiltersMenuOverlay(closeMenu: closeMenu),
      child: const _MenuButton(),
    );
  }
}

class _MenuButton extends ConsumerWidget {
  const _MenuButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;

    final currentFilter = ref.watch(feedCurrentFilterProvider);

    final bigIcon = currentFilter.category.getIcon(context);
    final smallIcon = currentFilter.filter.getIcon(
      context,
      size: 12.0.s,
      color: colors.secondaryBackground,
    );

    return Stack(
      children: [
        SizedBox.square(
          dimension: 40.0.s,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: currentFilter.category.getColor(context),
              borderRadius: BorderRadius.circular(16.0.s),
            ),
            child: Center(child: bigIcon),
          ),
        ),
        PositionedDirectional(
          end: 0,
          bottom: 0,
          child: Transform.translate(
            offset: Offset(3.0.s, 3.0.s),
            child: SizedBox.square(
              dimension: 18.0.s,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: currentFilter.category.getColor(context),
                  borderRadius: BorderRadius.circular(20.0.s),
                  border: Border.all(
                    color: colors.secondaryBackground,
                    width: 1.0.s,
                  ),
                ),
                child: Center(child: smallIcon),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
