// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/enums/community_token_trade_mode.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_selector_data.f.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/components/balance/coin_usd_amount.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/model/selected_crypto_wallet_data.f.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/providers/network_selector_notifier.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/providers/selected_crypto_wallet_notifier.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/receive_coins/providers/receive_coins_form_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/providers/swap_coins_controller_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/balance/balance_actions.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/logger/logger.dart';

class Balance extends HookConsumerWidget {
  const Balance({
    required this.coinsGroup,
    this.selectedNetwork,
    super.key,
  });

  final CoinsGroup coinsGroup;
  final SelectedNetworkItem? selectedNetwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize cache from coinsGroup data (computed once, cached)
    final initialCache = useMemoized(
      () {
        final cache = <String, (double, double)>{};

        // Calculate "ALL" networks balance
        var totalAmount = 0.0;
        var totalBalanceUSD = 0.0;
        for (final coin in coinsGroup.coins) {
          totalAmount += coin.amount;
          totalBalanceUSD += coin.balanceUSD;
        }
        cache['ALL'] = (totalAmount, totalBalanceUSD);

        // Calculate per-network balances
        for (final coin in coinsGroup.coins) {
          final networkId = coin.coin.network.id;
          final current = cache[networkId] ?? (0.0, 0.0);
          cache[networkId] = (
            current.$1 + coin.amount,
            current.$2 + coin.balanceUSD,
          );
        }

        Logger.info('[UI] Balance cache initialized with ${cache.length} networks: ${cache.keys.toList()}');
        return cache;
      },
      [coinsGroup],
    );

    // Cache for instant balance display on network switch
    final balanceCache = useState(initialCache);

    // Sync cache if coinsGroup changes (e.g., after pull-to-refresh)
    useEffect(
      () {
        balanceCache.value = {...balanceCache.value, ...initialCache};
        return null;
      },
      [initialCache],
    );

    // Use optimistic selectedNetwork for instant cache lookup
    final networkKey = selectedNetwork?.maybeMap(
      network: (n) => n.network.id,
      orElse: () => 'ALL',
    ) ?? 'ALL';

    // Watch provider network for other uses (swap, receive actions)
    final currentNetwork = ref.watch(
      networkSelectorNotifierProvider(symbolGroup: coinsGroup.symbolGroup).select(
        (asyncState) => asyncState.valueOrNull?.selected.mapOrNull(
          network: (item) => item.network,
        ),
      ),
    );

    Logger.info('[UI] Balance widget rebuild, networkKey: $networkKey');
    final cachedBalance = balanceCache.value[networkKey];

    final cryptoWalletData = ref.watch(
      selectedCryptoWalletNotifierProvider(symbolGroup: coinsGroup.symbolGroup),
    ).valueOrNull ?? SelectedCryptoWalletData.empty();
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
              cachedAmount: cachedBalance?.$1,
              cachedBalanceUSD: cachedBalance?.$2,
              onBalanceUpdated: (amount, balanceUSD) {
                final current = balanceCache.value[networkKey];
                if (current?.$1 != amount || current?.$2 != balanceUSD) {
                  Logger.info('[UI] Balance cache updated for $networkKey: ($amount, $balanceUSD) was: $current');
                  balanceCache.value = {
                    ...balanceCache.value,
                    networkKey: (amount, balanceUSD),
                  };
                }
              },
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(bottom: 20.0.s, top: 11.0.s),
            child: BalanceActions(
              onSwap: () {
                // Check if this is a tokenized community token
                final coin = coinsGroup.coins.firstOrNull?.coin;
                final externalAddress = coin?.tokenizedCommunityExternalAddress;

                if (externalAddress != null) {
                  // Open TC swap dialog
                  TradeCommunityTokenRoute(
                    externalAddress: externalAddress,
                    initialMode: CommunityTokenTradeMode.sell,
                  ).push<void>(context);
                } else {
                  // Open general swap dialog
                  ref.read(swapCoinsControllerProvider.notifier).initSellCoin(
                        coin: coinsGroup,
                        network: currentNetwork,
                      );

                  SwapCoinsRoute().push<void>(context);
                }
              },
              onReceive: () {
                final network = ref
                    .read(
                      networkSelectorNotifierProvider(symbolGroup: coinsGroup.symbolGroup),
                    )
                    .valueOrNull
                    ?.selected
                    .mapOrNull(network: (network) => network.network);
                final wallet = ref
                    .read(
                      selectedCryptoWalletNotifierProvider(symbolGroup: coinsGroup.symbolGroup),
                    )
                    .valueOrNull
                    ?.selectedWallet;

                final formNotifier = ref.read(receiveCoinsFormControllerProvider.notifier)
                  ..setCoin(coinsGroup);

                if (network != null && wallet?.address != null) {
                  formNotifier
                    ..setNetwork(network)
                    ..setWalletAddress(wallet!.address!);
                  ShareAddressToGetCoinsRoute().push<void>(context);
                } else {
                  NetworkSelectReceiveRoute().push<void>(context);
                }
              },
              onNeedToEnable2FA: () => SecureAccountModalRoute().push<void>(context),
              onMore: () {
                final network = ref
                    .read(
                      networkSelectorNotifierProvider(symbolGroup: coinsGroup.symbolGroup),
                    )
                    .valueOrNull
                    ?.selected
                    .mapOrNull(network: (n) => n.network);

                final wallet = ref
                    .read(
                      selectedCryptoWalletNotifierProvider(symbolGroup: coinsGroup.symbolGroup),
                    )
                    .valueOrNull
                    ?.selectedWallet;

                WalletMainModalRoute(
                  symbolGroup: coinsGroup.symbolGroup,
                  networkId: network?.id,
                  walletId: wallet?.id,
                ).push<void>(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
