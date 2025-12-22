// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/overlay_menu/components/overlay_menu_item.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu_container.dart';
import 'package:ion/app/components/separated/separated_column.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/creator_tokens/models/token_type_filter.dart';
import 'package:ion/app/features/user/pages/creator_tokens/providers/creator_tokens_filter_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

class TokenTypeFilterMenu extends ConsumerWidget {
  const TokenTypeFilterMenu({
    required this.closeMenu,
    super.key,
  });

  final VoidCallback closeMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(creatorTokensFilterNotifierProvider);

    return OverlayMenuContainer(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 200.0.s),
        child: SeparatedColumn(
          mainAxisSize: MainAxisSize.min,
          separator: const HorizontalSeparator(),
          children: [
            for (final filter in TokenTypeFilter.values)
              _TokenTypeFilterItem(
                filter: filter,
                isSelected: selectedFilter == filter,
                closeMenu: closeMenu,
              ),
          ],
        ),
      ),
    );
  }
}

class _TokenTypeFilterItem extends ConsumerWidget {
  const _TokenTypeFilterItem({
    required this.filter,
    required this.isSelected,
    required this.closeMenu,
  });

  final TokenTypeFilter filter;
  final bool isSelected;
  final VoidCallback closeMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;

    return OverlayMenuItem(
      label: filter.getLabel(context),
      labelColor: colors.primaryText,
      verticalPadding: 12.0.s,
      icon: isSelected
          ? Assets.svg.iconDappCheck.icon(
              color: colors.success,
              size: 18.0.s,
            )
          : SizedBox(width: 18.0.s),
      onPressed: () {
        ref.read(creatorTokensFilterNotifierProvider.notifier).filter = filter;
        closeMenu();
      },
    );
  }
}
