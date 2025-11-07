// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/icons/coin_icon.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/transaction_status.f.dart';
import 'package:ion/app/features/wallets/model/transaction_type.dart';
import 'package:ion/app/features/wallets/providers/current_nfts_provider.r.dart';
import 'package:ion/app/features/wallets/providers/transaction_provider.r.dart';
import 'package:ion/app/features/wallets/views/components/nft_item.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/send_coins/components/confirmation/transaction_amount_summary.dart';
import 'package:ion/app/features/wallets/views/pages/transaction_details/transaction_details.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/services/share/share.dart';
import 'package:ion/generated/assets.gen.dart';

class TransactionResultSheet extends HookConsumerWidget {
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

    final assetAbbreviation = transactionData.valueOrNull?.assetData
        .mapOrNull(coin: (coin) => coin.coinsGroup)
        ?.abbreviation;

    final disableShareButton = abbreviationsToExclude.contains(assetAbbreviation) &&
        transactionData.valueOrNull?.status != TransactionStatus.confirmed;

    final colors = context.theme.appColors;
    final textTheme = context.theme.appTextThemes;
    final locale = context.i18n;
    const icons = Assets.svg;

    const loadingContent = Center(child: IONLoadingIndicator());

    final nftsProvider = ref.watch(currentNftsNotifierProvider.notifier);
    useEffect(() => nftsProvider.allowRefresh, []);

    return SheetContent(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationAppBar.modal(
            showBackButton: false,
            actions: const [NavigationCloseButton()],
          ),
          ScreenSideOffset.small(
            child: transactionData.when(
              skipLoadingOnReload: true,
              loading: () => loadingContent,
              error: (_, __) {
                return Column(
                  children: [
                    icons.actionContactsendError.iconWithDimensions(
                      width: 74.0.s,
                      height: 76.0.s,
                    ),
                    SizedBox(height: 10.s),
                    Text(
                      locale.error_general_title,
                      style: textTheme.title,
                    ),
                    SizedBox(height: 12.s),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.tertiaryBackground,
                        borderRadius: BorderRadius.circular(16.0.s),
                        border: Border.all(color: colors.onTertiaryFill),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.s, horizontal: 16.s),
                      child: Text(
                        locale.wallet_transaction_general_error_desc,
                        textAlign: TextAlign.center,
                        style: textTheme.body2.copyWith(
                          color: colors.secondaryText,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.0.s),
                    Button(
                      label: Text(locale.wallet_back_to_wallet),
                      mainAxisSize: MainAxisSize.max,
                      onPressed: Navigator.of(context, rootNavigator: true).pop,
                    ),
                  ],
                );
              },
              data: (transactionData) {
                if (transactionData == null) return loadingContent;

                return Column(
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
                          disabled: disableShareButton,
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
                );
              },
            ),
          ),
          ScreenBottomOffset(margin: 16.0.s),
        ],
      ),
    );
  }
}
