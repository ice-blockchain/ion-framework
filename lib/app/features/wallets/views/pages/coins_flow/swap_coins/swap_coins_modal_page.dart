// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/icons/coin_icon.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class SwapCoinsModalPage extends ConsumerWidget {
  const SwapCoinsModalPage({
    required this.initialCoinsGroupSymbol,
    super.key,
  });

  final String initialCoinsGroupSymbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletView = ref.watch(currentWalletViewDataProvider).requireValue;
    final initialCoins = walletView.coinGroups.firstWhere((e) => e.symbolGroup == initialCoinsGroupSymbol);

    return SheetContent(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0.s),
            child: NavigationAppBar.screen(
              title: Text(context.i18n.wallet_swap_coins),
              actions: const [
                _SlippageAction(),
              ],
            ),
          ),
          SizedBox(
            height: 12.0.s,
          ),
          _TokenCard(
            type: _TokenCardType.from,
            coinsGroup: initialCoins,
          ),
          SizedBox(
            height: 10.0.s,
          ),
          const _TokenCard(
            type: _TokenCardType.to,
            coinsGroup: null,
          ),
        ],
      ),
    );
  }
}

class _SlippageAction extends StatelessWidget {
  const _SlippageAction();

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    return Button(
      onPressed: () {
        // TODO(ice-erebus): implement slippage action
      },
      type: ButtonType.outlined,
      tintColor: colors.onTertiaryFill,
      borderRadius: BorderRadius.circular(10.0.s),
      leadingIcon: Assets.svg.iconButtonManagecoin.icon(
        color: colors.primaryText,
        size: 14.0.s,
      ),
      label: Text(
        '1%',
        style: textStyles.body2.copyWith(
          color: colors.primaryText,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(55.0.s, 26.0.s),
        padding: EdgeInsets.symmetric(
          horizontal: 10.0.s,
          vertical: 6.0.s,
        ),
      ),
    );
  }
}

enum _TokenCardType {
  from,
  to;
}

class _TokenCard extends ConsumerWidget {
  const _TokenCard({
    required this.type,
    required this.coinsGroup,
  });

  final _TokenCardType type;
  final CoinsGroup? coinsGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;
    final iconUrl = coinsGroup?.iconUrl;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 16.0.s,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 12.0.s,
        vertical: 16.0.s,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0.s),
        color: type == _TokenCardType.to ? colors.tertiaryBackground : Colors.transparent,
        border: type == _TokenCardType.from
            ? Border.all(
                color: colors.onTertiaryFill,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type == _TokenCardType.from ? context.i18n.wallet_swap_coins_sell : context.i18n.wallet_swap_coins_buy,
                style: textStyles.subtitle3.copyWith(
                  color: colors.onTertiaryBackground,
                ),
              ),
              if (type == _TokenCardType.from)
                Row(
                  spacing: 5.0.s,
                  children: [
                    _SumPercentageAction(
                      percentage: 25,
                      onPercentageChanged: (percentage) {
                        // TODO(ice-erebus): implement percentage changed
                      },
                    ),
                    _SumPercentageAction(
                      percentage: 50,
                      onPercentageChanged: (percentage) {
                        // TODO(ice-erebus): implement percentage changed
                      },
                    ),
                    _SumPercentageAction(
                      percentage: 75,
                      onPercentageChanged: (percentage) {
                        // TODO(ice-erebus): implement percentage changed
                      },
                    ),
                    _SumPercentageAction(
                      percentage: 100,
                      onPercentageChanged: (percentage) {
                        // TODO(ice-erebus): implement percentage changed
                      },
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(
            height: 16.0.s,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (iconUrl != null && coinsGroup != null)
                CoinIconWidget(
                  imageUrl: iconUrl,
                  type: WalletItemIconType.big(),
                )
              else
                Button(
                  onPressed: () {
                    // TODO(ice-erebus): implement select coin action
                  },
                  type: ButtonType.outlined,
                  label: Text(
                    context.i18n.wallet_swap_coins_select_coin,
                    style: textStyles.body.copyWith(
                      color: colors.secondaryBackground,
                    ),
                  ),
                  tintColor: colors.primaryAccent,
                  backgroundColor: colors.primaryAccent,
                  borderRadius: BorderRadius.circular(12.0.s),
                  leadingIcon: Assets.svg.iconCreatecoinNewcoin.icon(
                    color: colors.secondaryBackground,
                    size: 20.0.s,
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(128.0.s, 36.0.s),
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.0.s,
                      vertical: 6.0.s,
                    ),
                  ),
                ),
              TextField(
                readOnly: coinsGroup == null,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SumPercentageAction extends StatelessWidget {
  const _SumPercentageAction({
    required this.percentage,
    required this.onPercentageChanged,
  });

  final int percentage;
  final void Function(int) onPercentageChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;

    final textStyles = context.theme.appTextThemes;

    return GestureDetector(
      onTap: () {
        onPercentageChanged(percentage);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.0.s, vertical: 2.0.s),
        decoration: BoxDecoration(
          color: colors.attentionBlock,
          borderRadius: BorderRadius.circular(16.0.s),
        ),
        child: Text(
          '$percentage%',
          style: textStyles.caption3.copyWith(
            color: colors.quaternaryText,
          ),
        ),
      ),
    );
  }
}
