// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/components/balance/coin_usd_amount.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/providers/selected_crypto_wallet_notifier.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/receive_coins/providers/receive_coins_form_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/providers/swap_coins_controller_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/balance/balance_actions.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class Balance extends ConsumerWidget {
  const Balance({
    required this.coinsGroup,
    this.currentNetwork,
    super.key,
  });

  final CoinsGroup coinsGroup;
  final NetworkData? currentNetwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cryptoWalletData = ref.watch(selectedCryptoWalletNotifierProvider);
    final shouldShowWallets = cryptoWalletData.wallets.length > 1;

    return ScreenSideOffset.small(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(
              top: shouldShowWallets ? 16.s : 12.s,
            ),
            child: CoinUsdAmount(
              coinsGroup: coinsGroup,
              currentNetwork: currentNetwork,
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(bottom: 20.0.s, top: 11.0.s),
            child: BalanceActions(
              onSwap: () {
                ref.read(swapCoinsControllerProvider.notifier).initSellCoin(
                      coin: coinsGroup,
                      network: currentNetwork,
                    );

                SwapCoinsRoute().push<void>(context);
              },
              onReceive: () {
                ref.read(receiveCoinsFormControllerProvider.notifier).setCoin(coinsGroup);
                NetworkSelectReceiveRoute().push<void>(context);
              },
              onNeedToEnable2FA: () => SecureAccountModalRoute().push<void>(context),
              onMore: () {
                WalletMainModalRoute(symbolGroup: coinsGroup.symbolGroup).push<void>(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
