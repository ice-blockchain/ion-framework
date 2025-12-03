// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/views/components/coin_icon_with_network.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/sum_percentage_action.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/enums/coin_swap_type.dart';
import 'package:ion/app/utils/text_input_formatters.dart';
import 'package:ion/generated/assets.gen.dart';

class TokenCard extends StatelessWidget {
  const TokenCard({
    required this.type,
    required this.onTap,
    this.coinsGroup,
    this.network,
    this.controller,
    this.onPercentageChanged,
    super.key,
  });

  final CoinSwapType type;
  final CoinsGroup? coinsGroup;
  final NetworkData? network;
  final VoidCallback onTap;
  final TextEditingController? controller;
  final ValueChanged<int>? onPercentageChanged;

  @override
  Widget build(BuildContext context) {
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
        color: type == CoinSwapType.buy ? colors.tertiaryBackground : Colors.transparent,
        border: type == CoinSwapType.sell
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
                type == CoinSwapType.sell
                    ? context.i18n.wallet_swap_coins_sell
                    : context.i18n.wallet_swap_coins_buy,
                style: textStyles.subtitle3.copyWith(
                  color: colors.onTertiaryBackground,
                ),
              ),
              if (type == CoinSwapType.sell)
                Row(
                  spacing: 5.0.s,
                  children: [
                    SumPercentageAction(
                      percentage: 25,
                      onPercentageChanged: onPercentageChanged ?? (_) {},
                    ),
                    SumPercentageAction(
                      percentage: 50,
                      onPercentageChanged: onPercentageChanged ?? (_) {},
                    ),
                    SumPercentageAction(
                      percentage: 75,
                      onPercentageChanged: onPercentageChanged ?? (_) {},
                    ),
                    SumPercentageAction(
                      percentage: 100,
                      onPercentageChanged: onPercentageChanged ?? (_) {},
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(
            height: 16.0.s,
          ),
          GestureDetector(
            onTap: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (iconUrl != null && coinsGroup != null)
                  Row(
                    spacing: 10.0.s,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (network != null)
                        CoinIconWithNetwork.small(
                          iconUrl,
                          network: network!,
                        ),
                      Column(
                        spacing: 2.0.s,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                coinsGroup!.name,
                                style: textStyles.body.copyWith(
                                  color: colors.primaryText,
                                ),
                              ),
                              SizedBox(width: 4.0.s),
                              Assets.svg.iconArrowDown.icon(
                                color: colors.primaryText,
                                size: 6.0.s,
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.0.s, vertical: 2.0.s),
                            decoration: BoxDecoration(
                              color: colors.attentionBlock,
                              borderRadius: BorderRadius.circular(16.0.s),
                            ),
                            child: Text(
                              network?.displayName ?? '',
                              style: textStyles.caption3.copyWith(
                                color: colors.quaternaryText,
                                fontSize: 11.0.s,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Button(
                    onPressed: onTap,
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
                SizedBox(
                  width: 150.0.s,
                  child: TextField(
                    controller: controller,
                    readOnly: coinsGroup == null,
                    keyboardType: TextInputType.number,
                    style: textStyles.headline2.copyWith(
                      color: colors.primaryText,
                    ),
                    inputFormatters: [
                      CoinInputFormatter(),
                    ],
                    textAlign: TextAlign.end,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0.00',
                      hintStyle: textStyles.headline2.copyWith(
                        color: colors.tertiaryText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 8.0.s,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Assets.svg.iconWallet.icon(
                      color: colors.tertiaryText,
                      size: 12.0.s,
                    ),
                    SizedBox(
                      width: 4.0.s,
                    ),
                    Flexible(
                      child: Text(
                        coinsGroup != null
                            ? '${coinsGroup!.totalAmount} ${coinsGroup!.symbolGroup}'
                            : '0.00 ICE',
                        style: textStyles.caption2.copyWith(
                          color: colors.tertiaryText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                r'$0.00',
                style: textStyles.caption2.copyWith(
                  color: colors.tertiaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
