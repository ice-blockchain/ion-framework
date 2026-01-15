// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu_container.dart';
import 'package:ion/app/components/separated/separated_column.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/creator_tokens/models/token_type_filter.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/providers/wallet_coins_filter_provider.r.dart';

class WalletCoinsFilterMenu extends ConsumerWidget {
  const WalletCoinsFilterMenu({
    required this.closeMenu,
    super.key,
  });

  final VoidCallback closeMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(walletCoinsFilterNotifierProvider);

    return OverlayMenuContainer(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 140.0.s),
        child: SeparatedColumn(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
    final textStyles = context.theme.appTextThemes;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ref.read(walletCoinsFilterNotifierProvider.notifier).filter = filter;
        closeMenu();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 12.0.s),
        child: Text(
          filter.getLabel(context),
          style: textStyles.subtitle3.copyWith(
            color: colors.primaryText,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
