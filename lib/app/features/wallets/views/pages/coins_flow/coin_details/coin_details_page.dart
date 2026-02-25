// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/icons/coin_icon.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/components/scroll_view/pull_to_refresh_builder.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/enums/tokenized_community_token_type.f.dart';
import 'package:ion/app/features/tokenized_communities/utils/master_pubkey_resolver.dart';
import 'package:ion/app/features/wallets/domain/transactions/sync_transactions_service.r.dart';
import 'package:ion/app/features/wallets/model/info_type.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/features/wallets/views/components/info_block_button.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/components/balance/balance.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/components/coin_transaction_history/coin_transaction_history.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/components/crypto_wallets_switcher.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/components/transaction_list_item/transaction_list_header.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/providers/coin_transaction_history_notifier_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/providers/selected_crypto_wallet_notifier.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';

class CoinDetailsPage extends ConsumerWidget {
  const CoinDetailsPage({required this.symbolGroup, super.key});

  final String symbolGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletView = ref.watch(currentWalletViewDataProvider).requireValue;
    final coinsGroup = walletView.coinGroups.firstWhere((e) => e.symbolGroup == symbolGroup);

    final historyNotifier = ref.watch(
      coinTransactionHistoryNotifierProvider(symbolGroup: symbolGroup).notifier,
    );
    final hasMore =
        ref.watch(
          coinTransactionHistoryNotifierProvider(symbolGroup: symbolGroup).select(
            (state) => state.valueOrNull?.hasMore ?? false,
          ),
        );

    final containsTier2Network = coinsGroup.coins.any((coin) => coin.coin.network.tier != 1);

    final cryptoWalletData = ref.watch(
      selectedCryptoWalletNotifierProvider(symbolGroup: symbolGroup),
    );

    return Scaffold(
      appBar: NavigationAppBar.screen(
        title: GestureDetector(
          onTap: () {
            final firstCoin = coinsGroup.coins.firstOrNull?.coin;
            if (firstCoin == null) return;

            final tokenType = firstCoin.tokenizedCommunityTokenType;
            final externalAddress = firstCoin.tokenizedCommunityExternalAddress;

            if (tokenType == null || externalAddress == null) return;

            switch (tokenType) {
              case TokenizedCommunityTokenType.tokenTypeProfile:
                final pubkey = MasterPubkeyResolver.resolve(externalAddress);
                ProfileRoute(pubkey: pubkey).push<void>(context);
              case TokenizedCommunityTokenType.tokenTypePost:
              case TokenizedCommunityTokenType.tokenTypeArticle:
              case TokenizedCommunityTokenType.tokenTypeVideo:
              case TokenizedCommunityTokenType.tokenTypeXcom:
                TokenizedCommunityRoute(externalAddress: externalAddress).push<void>(context);
              case TokenizedCommunityTokenType.tokenTypeUndefined:
                break;
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CoinIconWidget(imageUrl: coinsGroup.iconUrl, type: WalletItemIconType.medium()),
              SizedBox(width: 6.0.s),
              Flexible(
                child: Text(
                  coinsGroup.name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (containsTier2Network) ...[
                SizedBox(width: 2.0.s),
                const InfoBlockButton(
                  infoType: InfoType.transactionsInTier2Network,
                ),
              ],
            ],
          ),
        ),
      ),
      body: LoadMoreBuilder(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SectionSeparator(),
                if (cryptoWalletData.wallets.length > 1)
                  Padding(
                    padding: EdgeInsetsDirectional.only(top: 20.s),
                    child: CryptoWalletSwitcher(
                      wallets: cryptoWalletData.wallets,
                      selectedWallet: cryptoWalletData.selectedWallet,
                      onWalletChanged: (wallet) {
                        ref
                            .read(
                              selectedCryptoWalletNotifierProvider(symbolGroup: symbolGroup)
                                  .notifier,
                            )
                            .selectedWallet = wallet;
                      },
                    ),
                  ),
                Balance(coinsGroup: coinsGroup),
                const SectionSeparator(),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: TransactionListHeader(symbolGroup: symbolGroup),
          ),
          CoinTransactionHistory(
            symbolGroup: symbolGroup,
            coinsGroup: coinsGroup,
          ),
          SliverToBoxAdapter(
            child: ScreenBottomOffset(),
          ),
        ],
        hasMore: hasMore,
        onLoadMore: historyNotifier.loadMore,
        builder: (context, slivers) => PullToRefreshBuilder(
          onRefresh: () async {
            ref
              ..invalidate(walletViewsDataNotifierProvider)
              ..invalidate(coinTransactionHistoryNotifierProvider(symbolGroup: symbolGroup));

            final syncService = await ref.read(syncTransactionsServiceProvider.future);
            await syncService.syncCoinTransactions(symbolGroup);
          },
          slivers: slivers,
        ),
      ),
    );
  }
}
