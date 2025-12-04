// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/inputs/text_input/ion_text_field.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/views/components/coin_icon_with_network.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/enums/coin_swap_type.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/providers/swap_coins_controller_provider.r.dart';
import 'package:ion/app/features/wallets/views/utils/amount_parser.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/utils/text_input_formatters.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_swap_client/models/swap_quote_info.m.dart';

class SwapCoinsModalPage extends HookConsumerWidget {
  const SwapCoinsModalPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(swapCoinsControllerProvider.notifier);
    final sellCoins = ref.watch(swapCoinsControllerProvider).sellCoin;
    final sellNetwork = ref.watch(swapCoinsControllerProvider).sellNetwork;
    final buyCoins = ref.watch(swapCoinsControllerProvider).buyCoin;
    final buyNetwork = ref.watch(swapCoinsControllerProvider).buyNetwork;
    final swapQuoteInfo = ref.watch(swapCoinsControllerProvider).swapQuoteInfo;
    final quoteAmount = ref.watch(swapCoinsControllerProvider).swapQuoteInfo;
    final amount = ref.watch(swapCoinsControllerProvider).amount;
    final isContinueButtonEnabled = sellCoins != null &&
        buyCoins != null &&
        sellNetwork != null &&
        buyNetwork != null &&
        swapQuoteInfo != null;

    final amountController = useTextEditingController();
    final quoteController = useTextEditingController();

    useAmountListener(
      amountController,
      controller,
      amount,
    );

    useQuoteDisplay(
      quoteController,
      quoteAmount,
      amount,
    );

    return SheetContent(
      body: Column(
        mainAxisSize: MainAxisSize.min,
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
          Stack(
            children: [
              Column(
                children: [
                  _TokenCard(
                    type: CoinSwapType.sell,
                    coinsGroup: sellNetwork != null ? sellCoins : null,
                    network: sellNetwork,
                  ),
                  SizedBox(
                    height: 10.0.s,
                  ),
                  _TokenCard(
                    type: CoinSwapType.buy,
                    coinsGroup: buyNetwork != null ? buyCoins : null,
                    network: buyNetwork,
                  ),
                ],
              ),
              const PositionedDirectional(
                top: 0,
                start: 0,
                end: 0,
                bottom: 0,
                child: _SwapButton(),
              ),
            ],
          ),
          if (sellCoins != null && buyCoins != null)
            _ConversionInfoRow(
              providerName: 'CEX + DEX',
              sellCoin: sellCoins,
              buyCoin: buyCoins,
            )
          else
            SizedBox(
              height: 32.0.s,
            ),
          _ContinueButton(
            isEnabled: isContinueButtonEnabled,
            onPressed: () async {
              if (isContinueButtonEnabled) {
                final result = await SwapCoinsConfirmationRoute().push<bool?>(context);
                if (result != null && result == true) {
                  /// Waiting until confirmation page is closed
                  Future.delayed(const Duration(milliseconds: 50), () {
                    if (context.mounted) {
                      context.pop();
                    }
                  });
                }
              }
            },
          ),
          SizedBox(
            height: 16.0.s,
          ),
        ],
      ),
    );
  }

  void useAmountListener(
    TextEditingController amountController,
    SwapCoinsController controller,
    double currentAmount,
  ) {
    final isUpdatingFromState = useRef(false);

    useEffect(
      () {
        void listener() {
          if (isUpdatingFromState.value) return;

          final val = parseAmount(amountController.text) ?? 0;
          controller.setAmount(val);
        }

        amountController.addListener(listener);
        return () => amountController.removeListener(listener);
      },
      [amountController, controller],
    );

    useEffect(
      () {
        final currentText = parseAmount(amountController.text) ?? 0;
        if ((currentText - currentAmount).abs() > 0.0001) {
          isUpdatingFromState.value = true;
          amountController.text = currentAmount.toString();
          isUpdatingFromState.value = false;
        }
        return null;
      },
      [currentAmount, amountController],
    );
  }

  void useQuoteDisplay(
    TextEditingController quoteController,
    SwapQuoteInfo? quoteAmount,
    double amount,
  ) {
    useEffect(
      () {
        if (quoteAmount != null) {
          final quoteValue = (quoteAmount.priceForSellTokenInBuyToken * amount).toString();
          if (quoteController.text != quoteValue) {
            quoteController.text = quoteValue;
          }
        } else if (quoteAmount == null && quoteController.text.isNotEmpty) {
          quoteController.clear();
        }
        return null;
      },
      [quoteAmount, quoteController, amount],
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

class _TokenCard extends ConsumerWidget {
  const _TokenCard({
    required this.type,
    this.coinsGroup,
    this.network,
  });

  final CoinSwapType type;
  final CoinsGroup? coinsGroup;
  final NetworkData? network;

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
          GestureDetector(
            onTap: () {
              SwapSelectCoinRoute(
                coinType: type,
              ).push<void>(context);
            },
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
                    onPressed: () {
                      SwapSelectCoinRoute(
                        coinType: type,
                      ).push<void>(context);
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
                SizedBox(
                  width: 150.0.s,
                  child: IonTextField(
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
              Row(
                children: [
                  Assets.svg.iconWallet.icon(
                    color: colors.tertiaryText,
                    size: 12.0.s,
                  ),
                  SizedBox(
                    width: 4.0.s,
                  ),
                  Text(
                    coinsGroup != null
                        ? '${coinsGroup!.totalAmount} ${coinsGroup!.symbolGroup}'
                        : '0.00 ICE',
                    style: textStyles.caption2.copyWith(
                      color: colors.tertiaryText,
                    ),
                  ),
                ],
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

class _SwapButton extends ConsumerWidget {
  const _SwapButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;

    return GestureDetector(
      onTap: () {
        ref.read(swapCoinsControllerProvider.notifier).switchCoins();
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.0.s),
        child: Center(
          child: Container(
            width: 34.0.s,
            height: 34.0.s,
            decoration: BoxDecoration(
              color: colors.tertiaryBackground,
              borderRadius: BorderRadius.circular(12.0.s),
              border: Border.all(
                color: colors.secondaryBackground,
                width: 3,
              ),
            ),
            child: Center(
              child: Assets.svg.iconamoonSwap.icon(
                color: colors.primaryText,
                size: 24.0.s,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.isEnabled,
    required this.onPressed,
  });

  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0.s),
      child: Button(
        onPressed: onPressed,
        label: Text(
          context.i18n.wallet_swap_coins_continue,
          style: textStyles.body.copyWith(
            color: colors.secondaryBackground,
          ),
        ),
        backgroundColor: isEnabled ? colors.primaryAccent : colors.sheetLine.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16.0.s),
        trailingIcon: Assets.svg.iconButtonNext.icon(
          color: colors.secondaryBackground,
          size: 24.0.s,
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, 56.0.s),
          padding: EdgeInsets.symmetric(
            horizontal: 109.0.s,
            vertical: 16.0.s,
          ),
        ),
      ),
    );
  }
}

// TODO(ice-erebus): add high impact and not enough states
class _ConversionInfoRow extends StatelessWidget {
  const _ConversionInfoRow({
    required this.providerName,
    required this.sellCoin,
    required this.buyCoin,
  });

  final String providerName;
  final CoinsGroup sellCoin;
  final CoinsGroup buyCoin;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.0.s,
        vertical: 25.0.s,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // TODO(ice-erebus): implement conversion info
          Text(
            '1 ${sellCoin.name} = X ${buyCoin.name}',
            style: textStyles.body2.copyWith(),
          ),
          Row(
            spacing: 4.0.s,
            children: [
              Text(
                providerName,
                style: textStyles.body2.copyWith(),
              ),
              Assets.svg.iconBlockInformation.icon(
                color: colors.tertiaryText,
                size: 16.0.s,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
