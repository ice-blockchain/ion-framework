// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/providers/search_coins_notifier_provider.r.dart';
import 'package:ion/app/features/wallets/views/components/select_coin_modal_page.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/enums/coin_swap_type.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/providers/swap_coins_controller_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/utils/swap_coin_identifier.dart';
import 'package:ion/app/router/app_routes.gr.dart';

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
    final swapState = ref.watch(swapCoinsControllerProvider);
    final sellCoin = swapState.sellCoin;
    final sellNetwork = swapState.sellNetwork;
    final buyCoin = swapState.buyCoin;
    final buyNetwork = swapState.buyNetwork;

    // special filter for ceases of internal coins
    AsyncValue<List<CoinsGroup>> selector(AsyncValue<List<CoinsGroup>> coinGroups) {
      final otherCoin = switch (type) {
        CoinSwapType.sell => buyCoin,
        CoinSwapType.buy => sellCoin,
      };
      final otherNetwork = switch (type) {
        CoinSwapType.sell => buyNetwork,
        CoinSwapType.buy => sellNetwork,
      };

      if (otherCoin == null || otherNetwork == null) {
        return coinGroups;
      }

      if (type == CoinSwapType.sell && !SwapCoinIdentifier.isInternalCoin(buyCoin, buyNetwork)) {
        return coinGroups;
      }
      if (type == CoinSwapType.buy && !SwapCoinIdentifier.isInternalCoin(sellCoin, sellNetwork)) {
        return coinGroups;
      }

      return coinGroups.whenData((coinList) {
        return coinList.where((coin) {
          if (!SwapCoinIdentifier.isInternalCoinGroup(coin)) {
            return false;
          }
          //in case of ice BSC coin there is no coin in ICE we can swap for
          if (SwapCoinIdentifier.isIceCoinGroup(coin) &&
              SwapCoinIdentifier.isIceBsc(otherCoin, otherNetwork)) {
            return false;
          }
          return true;
        }).toList();
      });
    }

    return SelectCoinModalPage(
      showBackButton: true,
      showCloseButton: false,
      coinsProvider: searchCoinsNotifierProvider.select(selector),
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
          // Show slippage settings page when sell coin and network are selected
          // Skip for special ICE/ION swaps (1:1 swaps)
          if (type == CoinSwapType.sell) {
            final swapState = ref.read(swapCoinsControllerProvider);
            final sellCoin = swapState.sellCoin;
            final sellNetwork = swapState.sellNetwork;

            // Check if this is a special swap (will be 1:1, no slippage needed)
            final isSpecialSwap = SwapCoinIdentifier.isInternalCoin(sellCoin, sellNetwork);

            if (!isSpecialSwap && context.mounted) {
              await SwapSlippageSettingsRoute().push<void>(context);
              await Future.delayed(
                const Duration(milliseconds: 50),
                () {
                  if (context.mounted) {
                    context.pop();
                  }
                },
              );
            } else {
              // For special swaps, just pop back
              await Future.delayed(
                const Duration(milliseconds: 50),
                () {
                  if (context.mounted) {
                    context.pop();
                  }
                },
              );
            }
          } else {
            await Future.delayed(
              const Duration(milliseconds: 50),
              () {
                if (context.mounted) {
                  context.pop();
                }
              },
            );
          }
        }
      },
    );
  }
}
