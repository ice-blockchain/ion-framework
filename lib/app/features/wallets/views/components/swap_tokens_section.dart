// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/views/components/coin_icon_with_network.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';

class SwapTokensSection extends StatelessWidget {
  const SwapTokensSection({
    required this.sellCoins,
    required this.sellNetwork,
    required this.buyCoins,
    required this.buyNetwork,
    required this.sellAmount,
    required this.buyAmount,
    super.key,
  });

  final CoinsGroup sellCoins;
  final NetworkData sellNetwork;
  final CoinsGroup buyCoins;
  final NetworkData buyNetwork;
  final String sellAmount;
  final String buyAmount;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    return Container(
      padding: EdgeInsets.all(16.s),
      child: Stack(
        children: [
          PositionedDirectional(
            top: 38.0.s,
            start: 0.0.s,
            child: Assets.svg.iconSwapArrows.iconWithDimensions(
              color: colors.sheetLine,
              height: 66.0.s,
              width: 34.0.s,
            ),
          ),
          Column(
            children: [
              _TokenRow(
                coinsGroup: sellCoins,
                network: sellNetwork,
                amount: sellAmount,
              ),
              SizedBox(height: 40.0.s),
              _TokenRow(
                coinsGroup: buyCoins,
                network: buyNetwork,
                amount: buyAmount,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TokenRow extends StatelessWidget {
  const _TokenRow({
    required this.coinsGroup,
    required this.network,
    required this.amount,
  });

  final CoinsGroup coinsGroup;
  final NetworkData network;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    final coinInWallet = coinsGroup.coins.firstWhereOrNull(
      (coin) => coin.coin.network.id == network.id,
    );

    final amountDouble = double.tryParse(amount.replaceAll(',', '')) ?? 0.0;
    final usdEquivalent = coinInWallet != null ? amountDouble * coinInWallet.coin.priceUSD : 0.0;
    final usdEquivalentFormatted = formatToCurrency(usdEquivalent);

    return Row(
      children: [
        CoinIconWithNetwork.small(
          coinsGroup.iconUrl,
          network: network,
        ),
        SizedBox(width: 12.0.s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$amount ${coinsGroup.abbreviation}',
                style: textStyles.title.copyWith(
                  color: colors.primaryText,
                ),
              ),
              Text(
                usdEquivalentFormatted,
                style: textStyles.caption2.copyWith(
                  color: colors.tertiaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
