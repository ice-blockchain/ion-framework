// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/icons/coin_icon.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/transaction_status.f.dart';
import 'package:ion/app/features/wallets/model/transaction_type.dart';
import 'package:ion/app/features/wallets/providers/transaction_provider.r.dart';
import 'package:ion/app/features/wallets/views/components/nft_item.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/send_coins/components/confirmation/transaction_amount_summary.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/services/share/share.dart';
import 'package:ion/generated/assets.gen.dart';

class TransactionResultSheet extends ConsumerWidget {
  const TransactionResultSheet({
    required this.walletViewId,
    required this.txHash,
    required this.transactionDetailsRouteLocationBuilder,
    super.key,
  });

  final String walletViewId;
  final String txHash;
  final String Function(String walletViewId, String txHash) transactionDetailsRouteLocationBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionData = ref.watch(
      transactionNotifierProvider(
        walletViewId: walletViewId,
        txHash: txHash,
      ),
    );

    if (transactionData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final colors = context.theme.appColors;
    final textTheme = context.theme.appTextThemes;
    final locale = context.i18n;
    const icons = Assets.svg;

    return SheetContent(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationAppBar.modal(
            showBackButton: false,
            actions: const [NavigationCloseButton()],
          ),
          ScreenSideOffset.small(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                icons.actionContactsendSuccess.iconWithDimensions(
                  width: 74.0.s,
                  height: 76.0.s,
                ),
                SizedBox(height: 10.0.s),
                Text(
                  locale.wallet_transaction_successful,
                  style: textTheme.title.copyWith(
                    color: colors.primaryAccent,
                  ),
                ),
                SizedBox(height: 24.0.s),
                transactionData.assetData.maybeMap(
                      coin: (coin) => TransactionAmountSummary(
                        amount: coin.amount,
                        currency: coin.coinsGroup.abbreviation,
                        usdAmount: coin.amountUSD,
                        icon: CoinIconWidget(
                          imageUrl: coin.coinsGroup.iconUrl,
                          type: WalletItemIconType.medium(),
                        ),
                        transactionType: TransactionType.send,
                        isFailed: transactionData.status == TransactionStatus.failed,
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
                SizedBox(height: 24.0.s),
                Row(
                  children: [
                    Expanded(
                      child: Button(
                        label: Text(locale.wallet_transaction_details),
                        leadingIcon: icons.iconButtonDetails.icon(
                          color: context.theme.appColors.secondaryText,
                        ),
                        backgroundColor: context.theme.appColors.tertiaryBackground,
                        type: ButtonType.outlined,
                        mainAxisSize: MainAxisSize.max,
                        onPressed: () {
                          context.push(
                            transactionDetailsRouteLocationBuilder(
                              transactionData.walletViewId,
                              transactionData.txHash,
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 13.0.s),
                    Button(
                      type: ButtonType.outlined,
                      onPressed: () {
                        shareContent(transactionData.transactionExplorerUrl);
                      },
                      backgroundColor: context.theme.appColors.tertiaryBackground,
                      leadingIcon: icons.iconButtonShare.icon(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ScreenBottomOffset(margin: 16.0.s),
        ],
      ),
    );
  }
}
