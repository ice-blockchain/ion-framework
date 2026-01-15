// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/coins/wallet_coins_filter_menu.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/providers/wallet_coins_filter_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

class WalletCoinsFilterDropdown extends HookWidget {
  const WalletCoinsFilterDropdown({
    this.scrollController,
    super.key,
  });

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final opened = useState(false);

    return OverlayMenu(
      scrollController: scrollController,
      onOpen: () => opened.value = true,
      onClose: () => opened.value = false,
      menuBuilder: (closeMenu) => WalletCoinsFilterMenu(closeMenu: closeMenu),
      child: _DropdownButton(opened: opened.value),
    );
  }
}

class _DropdownButton extends ConsumerWidget {
  const _DropdownButton({required this.opened});

  final bool opened;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(walletCoinsFilterNotifierProvider);
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 140.0.s),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            selectedFilter.getLabel(context),
            style: textStyles.subtitle3.copyWith(
              color: colors.onTertiaryBackground,
            ),
          ),
          SizedBox(width: 4.0.s),
          (opened ? Assets.svg.iconFilterArrowDown : Assets.svg.iconFilterArrowUp).icon(
            color: colors.onTertiaryBackground,
            size: 16.0.s,
          ),
        ],
      ),
    );
  }
}
