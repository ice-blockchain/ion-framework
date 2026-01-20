// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/coins/wallet_coins_filter_dropdown.dart';
import 'package:ion/generated/assets.gen.dart';

class WalletCoinsFilterBar extends StatelessWidget {
  const WalletCoinsFilterBar({
    this.scrollController,
    super.key,
  });

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    return ScreenSideOffset.small(
      child: Padding(
        padding: EdgeInsets.only(bottom: 12.0.s),
        child: Row(
          children: [
            Assets.svg.iconFilter.icon(
              color: colors.onTertiaryBackground,
              size: 16.0.s,
            ),
            SizedBox(width: 6.0.s),
            Text(
              context.i18n.creator_tokens_filter_title,
              style: textStyles.subtitle3.copyWith(
                color: colors.onTertiaryBackground,
              ),
            ),
            const Spacer(),
            WalletCoinsFilterDropdown(scrollController: scrollController),
          ],
        ),
      ),
    );
  }
}
