// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
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
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class SwapCoinsModalPage extends ConsumerWidget {
  const SwapCoinsModalPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellCoins = ref.watch(swapCoinsControllerProvider).sellCoin;
    final sellNetwork = ref.watch(swapCoinsControllerProvider).sellNetwork;
    final buyCoins = ref.watch(swapCoinsControllerProvider).buyCoin;
    final buyNetwork = ref.watch(swapCoinsControllerProvider).buyNetwork;
    final swapQuoteInfo = ref.watch(swapCoinsControllerProvider).swapQuoteInfo;
    final isContinueButtonEnabled =
        sellCoins != null && buyCoins != null && sellNetwork != null && buyNetwork != null && swapQuoteInfo != null;

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
}
