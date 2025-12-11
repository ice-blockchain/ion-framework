// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/providers/search_coins_notifier_provider.r.dart';
import 'package:ion/app/features/wallets/views/components/select_coin_modal_page.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/enums/coin_swap_type.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/providers/swap_coins_controller_provider.r.dart';

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
      coinsProvider: searchCoinsNotifierProvider,
      onQueryChanged: (query) {
        ref.read(searchCoinsNotifierProvider.notifier).search(query: query);
      },
      title: context.i18n.wallet_select_coin,
      onCoinSelected: (value) async {
        final result = await ref.read(swapCoinsControllerProvider.notifier).selectCoin(
              type: type,
              coin: value,
              selectNetworkRouteLocationBuilder: () async {
                final result = await context.push(selectNetworkRouteLocationBuilder());

                if (result is NetworkData) {
                  return result;
                }

                return null;
              },
            );

        if (result.coin != null && result.network != null) {
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
