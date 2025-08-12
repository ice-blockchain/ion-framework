// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/icons/coin_icon.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/select/select_container.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coin_in_wallet_data.f.dart';
import 'package:ion/app/features/wallets/views/utils/crypto_formatter.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';

class SelectCoinButton extends StatelessWidget {
  const SelectCoinButton({
    required this.selectedCoin,
    required this.onTap,
    this.enabled = true,
    super.key,
  });

  final CoinInWalletData? selectedCoin;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: selectedCoin == null
          ? const _NoCoinSelected()
          : _HasCoinSelected(
              selectedCoin: selectedCoin!,
              enabled: enabled,
            ),
    );
  }
}

class _NoCoinSelected extends StatelessWidget {
  const _NoCoinSelected();

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textTheme = context.theme.appTextThemes;

    return SelectContainer(
      child: Row(
        children: [
          Assets.svg.walletassets.icon(size: 30.0.s),
          SizedBox(width: 10.0.s),
          Text(
            context.i18n.common_select_coin_button_unselected,
            style: textTheme.body.copyWith(color: colors.primaryText),
          ),
        ],
      ),
    );
  }
}

class _HasCoinSelected extends StatelessWidget {
  const _HasCoinSelected({
    required this.selectedCoin,
    required this.enabled,
  });

  final CoinInWalletData selectedCoin;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textTheme = context.theme.appTextThemes;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.strokeElements),
        borderRadius: BorderRadius.circular(16.0.s),
        color: colors.secondaryBackground,
      ),
      child: ListItem(
        contentPadding: EdgeInsetsDirectional.only(
          start: ScreenSideOffset.defaultSmallMargin,
          end: 8.0.s,
        ),
        title: Text(
          selectedCoin.coin.name,
          style: textTheme.body,
        ),
        subtitle: Text(
          selectedCoin.coin.abbreviation,
          style: textTheme.caption3,
        ),
        backgroundColor: Colors.transparent,
        leading: CoinIconWidget(imageUrl: selectedCoin.coin.iconUrl, type: WalletItemIconType.big()),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCrypto(selectedCoin.amount),
                  style: textTheme.body,
                ),
                Text(
                  formatToCurrency(selectedCoin.balanceUSD),
                  style: textTheme.caption3.copyWith(
                    color: colors.secondaryText,
                  ),
                ),
              ],
            ),
            if (enabled)
              Padding(
                padding: EdgeInsets.all(8.0.s),
                child: Assets.svg.iconArrowDown.icon(),
              )
            else
              SizedBox.square(dimension: 10.0.s),
          ],
        ),
      ),
    );
  }
}
