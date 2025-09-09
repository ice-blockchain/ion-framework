// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ion/app/components/icons/coin_icon.dart';
import 'package:ion/app/components/icons/network_icon_widget.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/timeline_item_data.dart';
import 'package:ion/app/features/wallets/model/transaction_details.f.dart';
import 'package:ion/app/features/wallets/model/transaction_status.f.dart';
import 'package:ion/app/features/wallets/model/transaction_type.dart';
import 'package:ion/app/features/wallets/providers/transaction_provider.r.dart';
import 'package:ion/app/features/wallets/views/components/arrival_time/list_item_arrival_time.dart';
import 'package:ion/app/features/wallets/views/components/network_fee/list_item_network_fee.dart';
import 'package:ion/app/features/wallets/views/components/nft_item.dart';
import 'package:ion/app/features/wallets/views/components/timeline/timeline.dart';
import 'package:ion/app/features/wallets/views/components/transaction_participant.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/send_coins/components/confirmation/transaction_amount_summary.dart';
import 'package:ion/app/features/wallets/views/pages/transaction_details/transaction_details_actions.dart';
import 'package:ion/app/features/wallets/views/utils/crypto_formatter.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/services/share/share.dart';
import 'package:ion/generated/assets.gen.dart';

const _abbreviationsToExclude = {'TON', 'ION', 'ICE'};

class TransactionDetailsPage extends ConsumerWidget {
  const TransactionDetailsPage({
    required this.walletViewId,
    required this.txHash,
    required this.exploreRouteLocationBuilder,
    super.key,
  });

  final String txHash;
  final String walletViewId;
  final String Function(String url) exploreRouteLocationBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsync = ref.watch(
      transactionNotifierProvider(walletViewId: walletViewId, txHash: txHash),
    );

    return SheetContent(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationAppBar.modal(
            title: Text(context.i18n.transaction_details_title),
            actions: const [NavigationCloseButton()],
          ),
          Flexible(
            child: transactionAsync.when(
              data: (transactionData) => transactionData == null
                  ? const Center(child: IONLoadingIndicator())
                  : _TransactionDetailsContent(
                      transaction: transactionData,
                      onViewOnExplorer: () {
                        final url = transactionData.transactionExplorerUrl;
                        final location = exploreRouteLocationBuilder(url);
                        context.push<void>(location);
                      },
                    ),
              loading: () => const Center(child: IONLoadingIndicator()),
              error: (error, stackTrace) => const Center(child: IONLoadingIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionDetailsContent extends StatelessWidget {
  const _TransactionDetailsContent({required this.transaction, required this.onViewOnExplorer});

  final TransactionDetails transaction;
  final VoidCallback onViewOnExplorer;

  @override
  Widget build(BuildContext context) {
    final locale = context.i18n;
    // Calculate derived values
    final arrivalTime =
        transaction.status == TransactionStatus.confirmed && transaction.dateConfirmed != null
            ? DateFormat('dd.MM.yyyy HH:mm:ss').format(transaction.dateConfirmed!.toLocal())
            : transaction.networkFeeOption?.getDisplayArrivalTime(context);

    final participantAddress =
        transaction.type.isSend ? transaction.receiverAddress : transaction.senderAddress;

    final currentUserAddress =
        transaction.type.isSend ? transaction.senderAddress : transaction.receiverAddress;

    final assetAbbreviation =
        transaction.assetData.mapOrNull(coin: (coin) => coin.coinsGroup)?.abbreviation;

    final disableTransactionDetailsButtons = _abbreviationsToExclude.contains(assetAbbreviation) &&
        transaction.status != TransactionStatus.confirmed;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: ScreenSideOffset.small(
            child: Column(
              children: [
                transaction.assetData.maybeMap(
                      coin: (coin) => TransactionAmountSummary(
                        amount: coin.amount,
                        currency: coin.coinsGroup.abbreviation,
                        usdAmount: coin.amountUSD,
                        icon: CoinIconWidget(
                          imageUrl: coin.coinsGroup.iconUrl,
                          type: WalletItemIconType.medium(),
                        ),
                        isFailed: transaction.status == TransactionStatus.failed,
                        transactionType: transaction.type,
                      ),
                      nft: (nft) => Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 52.0.s,
                        ),
                        child: NftItem(
                          nftData: nft.nft,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                      orElse: () => const SizedBox(),
                    ) ??
                    const SizedBox(),
                SizedBox(height: 12.0.s),
                Timeline(
                  items: [
                    if (transaction.status == TransactionStatus.failed)
                      TimelineItemData(
                        title: locale.transaction_details_timeline_failed,
                        isFailed: true,
                      )
                    else
                      TimelineItemData(
                        title: locale.transaction_details_timeline_pending,
                        isDone: true,
                        date: transaction.dateRequested,
                      ),
                    TimelineItemData(
                      title: locale.transaction_details_timeline_executing,
                      isDone: transaction.dateBroadcasted != null ||
                          transaction.status == TransactionStatus.confirmed ||
                          transaction.status == TransactionStatus.broadcasted,
                    ),
                    TimelineItemData(
                      title: locale.transaction_details_timeline_successful,
                      isDone: transaction.dateConfirmed != null &&
                          transaction.status == TransactionStatus.confirmed,
                    ),
                  ],
                ),
                SizedBox(height: 12.0.s),
                TransactionParticipant(
                  address: participantAddress,
                  transactionType: transaction.type,
                  pubkey: transaction.participantPubkey,
                ),
                SizedBox(height: 12.0.s),
                if (currentUserAddress case final String userAddress)
                  ListItem.textWithIcon(
                    title: Text(locale.wallet_title),
                    value: transaction.walletViewName,
                    icon: Assets.svg.walletWalletblue.icon(size: 16.s),
                    secondary: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        userAddress,
                        textAlign: TextAlign.right,
                        style: context.theme.appTextThemes.caption3,
                      ),
                    ),
                  ),
                ...transaction.assetData.maybeMap(
                      coin: (coin) => [
                        SizedBox(height: 12.0.s),
                        ListItem.textWithIcon(
                          title: Text(locale.wallet_asset),
                          value: coin.coinsGroup.abbreviation,
                          icon: CoinIconWidget(
                            imageUrl: coin.coinsGroup.iconUrl,
                            type: WalletItemIconType.small(),
                          ),
                        ),
                      ],
                      orElse: () => const [SizedBox.shrink()],
                    ) ??
                    const [SizedBox.shrink()],
                SizedBox(height: 12.0.s),
                ListItem.textWithIcon(
                  title: Text(locale.send_nft_confirm_network),
                  value: transaction.network.displayName,
                  icon: NetworkIconWidget(
                    type: WalletItemIconType.small(),
                    imageUrl: transaction.network.image,
                  ),
                ),
                SizedBox(height: 12.0.s),
                if (arrivalTime != null) ...[
                  ListItemArrivalTime(formattedTime: arrivalTime),
                  SizedBox(height: 12.0.s),
                ],
                if (transaction.networkFeeOption != null &&
                    transaction.type == TransactionType.send) ...[
                  ListItemNetworkFee(
                    value: formatCrypto(
                      transaction.networkFeeOption!.amount,
                      transaction.networkFeeOption!.symbol,
                    ),
                  ),
                  SizedBox(height: 15.0.s),
                ],
                TransactionDetailsActions(
                  disableButtons: disableTransactionDetailsButtons,
                  onViewOnExplorer: onViewOnExplorer,
                  onShare: () => shareContent(transaction.transactionExplorerUrl),
                ),
                SizedBox(height: 8.0.s),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: ScreenBottomOffset(),
        ),
      ],
    );
  }
}
