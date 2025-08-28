// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ion/app/components/icons/coin_icon.dart';
import 'package:ion/app/components/icons/network_icon_widget.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/timeline_item_data.dart';
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
    required this.exploreRouteLocationBuilder,
    super.key,
  });

  final String Function(String url) exploreRouteLocationBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = context.i18n;
    final transactionData = ref.watch(transactionNotifierProvider)!;
    final arrivalTime = transactionData.status == TransactionStatus.confirmed &&
            transactionData.dateConfirmed != null
        ? DateFormat('dd.MM.yyyy HH:mm:ss').format(transactionData.dateConfirmed!.toLocal())
        : transactionData.networkFeeOption?.getDisplayArrivalTime(context);

    final participantAddress = transactionData.type.isSend
        ? transactionData.receiverAddress
        : transactionData.senderAddress;

    final currentUserAddress = transactionData.type.isSend
        ? transactionData.senderAddress
        : transactionData.receiverAddress;

    final assetAbbreviation =
        transactionData.assetData.mapOrNull(coin: (value) => value.coinsGroup)?.abbreviation;

    final disableExplorer = _abbreviationsToExclude.contains(assetAbbreviation) &&
        transactionData.status != TransactionStatus.confirmed;

    return SheetContent(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationAppBar.modal(
            title: Text(context.i18n.transaction_details_title),
            actions: const [NavigationCloseButton()],
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScreenSideOffset.small(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          transactionData.assetData.maybeMap(
                                coin: (coin) => TransactionAmountSummary(
                                  amount: coin.amount,
                                  currency: coin.coinsGroup.abbreviation,
                                  usdAmount: coin.amountUSD,
                                  icon: CoinIconWidget(
                                    imageUrl: coin.coinsGroup.iconUrl,
                                    type: WalletItemIconType.medium(),
                                  ),
                                  transactionType: transactionData.type,
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
                              if (transactionData.status == TransactionStatus.failed)
                                TimelineItemData(
                                  title: locale.transaction_details_timeline_failed,
                                  isFailed: true,
                                )
                              else
                                TimelineItemData(
                                  title: locale.transaction_details_timeline_pending,
                                  isDone: true,
                                  date: transactionData.dateRequested,
                                ),
                              TimelineItemData(
                                title: locale.transaction_details_timeline_executing,
                                isDone: transactionData.dateBroadcasted != null ||
                                    transactionData.status == TransactionStatus.confirmed ||
                                    transactionData.status == TransactionStatus.broadcasted,
                              ),
                              TimelineItemData(
                                title: locale.transaction_details_timeline_successful,
                                isDone: transactionData.dateConfirmed != null &&
                                    transactionData.status == TransactionStatus.confirmed,
                              ),
                            ],
                          ),
                          SizedBox(height: 12.0.s),
                          TransactionParticipant(
                            address: participantAddress,
                            transactionType: transactionData.type,
                            pubkey: transactionData.participantPubkey,
                          ),
                          SizedBox(height: 12.0.s),
                          if (currentUserAddress case final String userAddress)
                            ListItem.textWithIcon(
                              title: Text(locale.wallet_title),
                              value: transactionData.walletViewName,
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
                          ...transactionData.assetData.maybeMap(
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
                            title: Text(context.i18n.send_nft_confirm_network),
                            value: transactionData.network.displayName,
                            icon: NetworkIconWidget(
                              type: WalletItemIconType.small(),
                              imageUrl: transactionData.network.image,
                            ),
                          ),
                          SizedBox(height: 12.0.s),
                          if (arrivalTime != null) ...[
                            ListItemArrivalTime(formattedTime: arrivalTime),
                            SizedBox(height: 12.0.s),
                          ],
                          if (transactionData.networkFeeOption != null &&
                              transactionData.type == TransactionType.send) ...[
                            ListItemNetworkFee(
                              value: formatCrypto(
                                transactionData.networkFeeOption!.amount,
                                transactionData.networkFeeOption!.symbol,
                              ),
                            ),
                            SizedBox(height: 15.0.s),
                          ],
                          TransactionDetailsActions(
                            disableExplorer: disableExplorer,
                            onViewOnExplorer: () {
                              final url = transactionData.transactionExplorerUrl;
                              final location = exploreRouteLocationBuilder(url);
                              context.push<void>(location);
                            },
                            onShare: () => shareContent(transactionData.transactionExplorerUrl),
                          ),
                          SizedBox(height: 8.0.s),
                        ],
                      ),
                    ),
                  ),
                  ScreenBottomOffset(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
