// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/views/components/select_coin_modal_page.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/providers/swap_coins_controller_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/swap_coins_modal_page.dart';

// TODO(ice-erebus): add recent coins
class SwapSelectCoinPage extends ConsumerWidget {
  const SwapSelectCoinPage({
    required this.selectNetworkRouteLocationBuilder,
    required this.type,
    super.key,
  });

  final String Function() selectNetworkRouteLocationBuilder;
  final CoinSwapType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SelectCoinModalPage(
      showBackButton: true,
      showCloseButton: false,
      title: context.i18n.wallet_select_coin,
      onCoinSelected: (value) async {
        switch (type) {
          case CoinSwapType.sell:
            ref.read(swapCoinsControllerProvider.notifier).setSellCoin(value);
          case CoinSwapType.buy:
            ref.read(swapCoinsControllerProvider.notifier).setBuyCoin(value);
        }

        final result = await context.push(selectNetworkRouteLocationBuilder());
        if (result is NetworkData) {
          switch (type) {
            case CoinSwapType.sell:
              ref.read(swapCoinsControllerProvider.notifier).setSellNetwork(result);
            case CoinSwapType.buy:
              ref.read(swapCoinsControllerProvider.notifier).setBuyNetwork(result);
          }

          /// Waiting until network list is closed
          await Future.delayed(
            const Duration(milliseconds: 50),
            () {
              if (context.mounted) {
                context.pop();
              }
            },
          );
        }
      },
    );
  }
}
