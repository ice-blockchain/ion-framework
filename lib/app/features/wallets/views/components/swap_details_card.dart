// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/shapes/bottom_notch_rect_border.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/views/components/swap_tokens_section.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_swap_client/models/swap_quote_info.m.dart';

class SwapDetailsCard extends HookWidget {
  const SwapDetailsCard({
    required this.sellCoins,
    required this.sellNetwork,
    required this.buyCoins,
    required this.buyNetwork,
    required this.sellAmount,
    required this.buyAmount,
    required this.swapType,
    required this.priceForSellTokenInBuyToken,
    required this.sellCoinAbbreviation,
    required this.buyCoinAbbreviation,
    required this.slippage,
    this.priceImpact,
    this.networkFee,
    this.protocolFee,
    this.initiallyExpanded = false,
    this.hideBuyAmount = false,
    super.key,
  });

  final CoinsGroup sellCoins;
  final NetworkData sellNetwork;
  final CoinsGroup buyCoins;
  final NetworkData buyNetwork;
  final String sellAmount;
  final String buyAmount;

  final SwapQuoteInfoType swapType;
  final double priceForSellTokenInBuyToken;
  final String sellCoinAbbreviation;
  final String buyCoinAbbreviation;
  final double? slippage;

  final double? priceImpact;
  final String? networkFee;
  final String? protocolFee;

  final bool initiallyExpanded;
  final bool hideBuyAmount;

  @override
  Widget build(BuildContext context) {
    final showMoreDetails = useState(initiallyExpanded);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwapTokensSection(
          sellCoins: sellCoins,
          sellNetwork: sellNetwork,
          buyCoins: buyCoins,
          buyNetwork: buyNetwork,
          sellAmount: sellAmount,
          buyAmount: buyAmount,
          hideBuyAmount: hideBuyAmount,
        ),
        SizedBox(height: 16.0.s),
        _SwapDetailsSection(
          showMoreDetails: showMoreDetails.value,
          onToggleDetails: () {
            showMoreDetails.value = !showMoreDetails.value;
          },
          swapType: swapType,
          priceForSellTokenInBuyToken: priceForSellTokenInBuyToken,
          sellCoinAbbreviation: sellCoinAbbreviation,
          buyCoinAbbreviation: buyCoinAbbreviation,
          slippage: slippage,
          priceImpact: priceImpact,
          networkFee: networkFee,
          protocolFee: protocolFee,
        ),
      ],
    );
  }
}

class _SwapDetailsSection extends StatelessWidget {
  const _SwapDetailsSection({
    required this.showMoreDetails,
    required this.onToggleDetails,
    required this.swapType,
    required this.priceForSellTokenInBuyToken,
    required this.sellCoinAbbreviation,
    required this.buyCoinAbbreviation,
    this.slippage,
    this.priceImpact,
    this.networkFee,
    this.protocolFee,
  });

  final bool showMoreDetails;
  final VoidCallback onToggleDetails;
  final SwapQuoteInfoType swapType;
  final double priceForSellTokenInBuyToken;
  final String sellCoinAbbreviation;
  final String buyCoinAbbreviation;
  final double? slippage;
  final double? priceImpact;
  final String? networkFee;
  final String? protocolFee;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;
    final isVisibleMoreButton = priceImpact != null || networkFee != null || protocolFee != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.0.s),
          padding: EdgeInsets.symmetric(
            horizontal: 12.0.s,
            vertical: 12.0.s,
          ),
          decoration: ShapeDecoration(
            color: colors.tertiaryBackground,
            shape: BottomNotchRectBorder(
              notchPosition: isVisibleMoreButton ? NotchPosition.bottom : NotchPosition.none,
            ),
          ),
          child: Column(
            children: [
              _DetailRow(
                label: context.i18n.wallet_swap_confirmation_provider,
                value: swapType == SwapQuoteInfoType.cexOrDex ? 'CEX + DEX' : 'Bridge',
              ),
              _Divider(),
              _DetailRow(
                label: context.i18n.wallet_swap_confirmation_price,
                value:
                    '1 $sellCoinAbbreviation = ${priceForSellTokenInBuyToken.formatMax6} $buyCoinAbbreviation',
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: showMoreDetails
                    ? Column(
                        children: [
                          if (priceImpact != null) ...[
                            _Divider(),
                            _DetailRow(
                              label: context.i18n.wallet_swap_confirmation_price_impact,
                              value: '${priceImpact!.toStringAsFixed(2)}%',
                            ),
                          ],
                          if (slippage != null) ...[
                            _Divider(),
                            _DetailRow(
                              label: context.i18n.wallet_swap_confirmation_slippage,
                              value: '${slippage!.toStringAsFixed(1)}%',
                            ),
                          ],
                          if (networkFee != null) ...[
                            _Divider(),
                            _DetailRow(
                              label: context.i18n.wallet_swap_confirmation_network_fee,
                              value: networkFee!,
                            ),
                          ],
                          if (protocolFee != null) ...[
                            _Divider(),
                            _DetailRow(
                              label: context.i18n.wallet_swap_confirmation_protocol_fee,
                              value: protocolFee!,
                            ),
                          ],
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        if (isVisibleMoreButton)
          Transform.translate(
            offset: Offset(0, -12.0.s),
            child: GestureDetector(
              onTap: onToggleDetails,
              child: Container(
                width: 82.s,
                padding: EdgeInsets.symmetric(
                  horizontal: 12.0.s,
                  vertical: 4.0.s,
                ),
                decoration: BoxDecoration(
                  color: colors.tertiaryBackground,
                  borderRadius: BorderRadius.circular(9.0.s),
                  border: Border.all(
                    color: colors.secondaryBackground,
                    width: 4.s,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      showMoreDetails
                          ? context.i18n.wallet_swap_confirmation_less
                          : context.i18n.wallet_swap_confirmation_more,
                      style: textStyles.caption2.copyWith(
                        color: colors.primaryText,
                      ),
                    ),
                    SizedBox(width: 4.0.s),
                    AnimatedRotation(
                      turns: showMoreDetails ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Assets.svg.iconArrowDown.icon(
                        color: colors.primaryText,
                        size: 16.0.s,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0.s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: textStyles.body2.copyWith(
                color: colors.quaternaryText,
              ),
            ),
          ),
          SizedBox(width: 12.0.s),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style:
                  textStyles.body2.copyWith(color: colors.primaryText, fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;

    return Container(
      height: 0.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.secondaryBackground,
            colors.onTertiaryFill,
            colors.secondaryBackground,
          ],
        ),
      ),
    );
  }
}
