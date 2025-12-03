// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/continue_button.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/conversion_info_row.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/slippage_action.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/swap_button.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/token_card.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/enums/coin_swap_type.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/providers/swap_coins_controller_provider.r.dart';
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
    final isContinueButtonEnabled = sellCoins != null &&
        buyCoins != null &&
        sellNetwork != null &&
        buyNetwork != null &&
        swapQuoteInfo != null;

    final amountController = useTextEditingController();
    final quoteController = useTextEditingController();

    useAmountListener(amountController, controller);
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
                SlippageAction(),
              ],
            ),
          ),
          Stack(
            children: [
              Column(
                children: [
                  TokenCard(
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
          if (sellCoins != null && buyCoins != null && sellNetwork != null && buyNetwork != null)
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
    );
  }

  void useAmountListener(
    TextEditingController amountController,
    SwapCoinsController controller,
  ) {
    useEffect(
      () {
        void listener() {
          final val = parseAmount(amountController.text) ?? 0;
          controller.setAmount(val);
        }

        amountController.addListener(listener);
        return () => amountController.removeListener(listener);
      },
      [amountController, controller],
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
