// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/swap_coin_data.f.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/continue_button.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/conversion_info_row.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/slippage_action.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/swap_button.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/token_card.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/enums/coin_swap_type.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/providers/swap_coins_controller_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/utils/swap_constants.dart';
import 'package:ion/app/features/wallets/views/utils/amount_parser.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
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
    final isQuoteLoading = ref.watch(swapCoinsControllerProvider).isQuoteLoading;
    final isContinueButtonEnabled = sellCoins != null &&
        buyCoins != null &&
        sellNetwork != null &&
        buyNetwork != null &&
        swapQuoteInfo != null &&
        !isQuoteLoading;

    final amountController = useTextEditingController();
    final quoteController = useTextEditingController();
    final isInsufficientFundsErrorState = useState(false);
    useEffect(
      () {
        var isCancelled = false;

        () async {
          final result =
              await ref.read(swapCoinsControllerProvider.notifier).isInsufficientFundsError();

          if (!isCancelled) {
            isInsufficientFundsErrorState.value = result;
          }
        }();

        return () {
          isCancelled = true;
        };
      },
      [amount, sellCoins, sellNetwork],
    );

    final sellCoinDecimals = _getCoinDecimals(sellCoins, sellNetwork);
    final buyCoinDecimals = _getCoinDecimals(buyCoins, buyNetwork);

    useAmountListener(
      amountController,
      controller,
      amount,
      sellCoinDecimals,
    );

    useQuoteDisplay(
      quoteController,
      quoteAmount,
      amount,
      buyCoinDecimals,
    );

    useResetSwapStateOnClose(controller);

    return SheetContent(
      body: SingleChildScrollView(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0.s),
                child: NavigationAppBar.screen(
                  title: Text(context.i18n.wallet_swap_coins),
                  actions: [
                    const SlippageAction(),
                    SizedBox(
                      width: 8.0.s,
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  Column(
                    children: [
                      TokenCard(
                        skipAmountFormatting: true,
                        isInsufficientFundsError: isInsufficientFundsErrorState.value,
                        skipValidation: true,
                        controller: amountController,
                        type: CoinSwapType.sell,
                        coinsGroup: sellNetwork != null ? sellCoins : null,
                        network: sellNetwork,
                        onTap: () {
                          SwapSelectCoinRoute(
                            coinType: CoinSwapType.sell,
                          ).push<void>(context);
                        },
                      ),
                      SizedBox(
                        height: 10.0.s,
                      ),
                      TokenCard(
                        skipAmountFormatting: true,
                        skipValidation: true,
                        isReadOnly: true,
                        controller: quoteController,
                        type: CoinSwapType.buy,
                        coinsGroup: buyNetwork != null ? buyCoins : null,
                        network: buyNetwork,
                        onTap: () {
                          SwapSelectCoinRoute(
                            coinType: CoinSwapType.buy,
                          ).push<void>(context);
                        },
                      ),
                    ],
                  ),
                  PositionedDirectional(
                    top: 0,
                    start: 0,
                    end: 0,
                    bottom: 0,
                    child: SwapButton(
                      onTap: () {
                        ref.read(swapCoinsControllerProvider.notifier).switchCoins();
                      },
                    ),
                  ),
                ],
              ),
              if (sellCoins != null && buyCoins != null)
                ConversionInfoRow(
                  sellCoin: sellCoins,
                  buyCoin: buyCoins,
                )
              else
                SizedBox(
                  height: 32.0.s,
                ),
              ContinueButton(
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
        ),
      ),
    );
  }

  int _getCoinDecimals(CoinsGroup? coins, NetworkData? network) {
    if (coins == null || network == null) return SwapConstants.defaultDecimals;

    final coin = coins.coins.firstWhereOrNull(
      (coin) => coin.coin.network.id == network.id,
    );

    return coin?.coin.decimals ?? SwapConstants.defaultDecimals;
  }

  void useAmountListener(
    TextEditingController amountController,
    SwapCoinsController controller,
    double currentAmount,
    int decimals,
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
          amountController.text = currentAmount.toStringAsFixed(decimals);
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
    int decimals,
  ) {
    useEffect(
      () {
        if (quoteAmount != null) {
          final quoteValue =
              (quoteAmount.priceForSellTokenInBuyToken * amount).toStringAsFixed(decimals);
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

  void useResetSwapStateOnClose(SwapCoinsController controller) {
    useEffect(
      () {
        // Clear buy coin immediately when modal opens

        // Reset slippage and clear buy coin when modal is closed
        return () {
          controller
            ..setSlippage(SwapCoinData.defaultSlippage)
            ..setBuyCoin(null)
            ..setBuyNetwork(null);
        };
      },
      [controller],
    );
  }
}
