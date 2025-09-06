// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/icons/coin_icon.dart';
import 'package:ion/app/components/icons/network_icon_widget.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/extensions/object.dart';
import 'package:ion/app/features/components/verify_identity/verify_identity_prompt_dialog_helper.dart';
import 'package:ion/app/features/wallets/domain/transactions/sync_transactions_service.r.dart';
import 'package:ion/app/features/wallets/model/crypto_asset_to_send_data.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/network_fee_option.f.dart';
import 'package:ion/app/features/wallets/model/transaction_type.dart';
import 'package:ion/app/features/wallets/providers/send_asset_form_provider.r.dart';
import 'package:ion/app/features/wallets/providers/send_coins_notifier_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/features/wallets/views/components/arrival_time/list_item_arrival_time.dart';
import 'package:ion/app/features/wallets/views/components/network_fee/list_item_network_fee.dart';
import 'package:ion/app/features/wallets/views/components/transaction_participant.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/send_coins/components/confirmation/transaction_amount_summary.dart';
import 'package:ion/app/features/wallets/views/utils/crypto_formatter.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_identity_client/ion_identity.dart';

class ConfirmationSheet extends ConsumerWidget {
  const ConfirmationSheet({
    required this.successRouteLocationBuilder,
    super.key,
  });

  final String Function(String walletViewId, String txHash) successRouteLocationBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = context.i18n;

    final formData = ref.watch(sendAssetFormControllerProvider);
    final coin = formData.assetData.as<CoinAssetToSendData>();

    ref
      ..displayErrors(
        sendCoinsNotifierProvider,
        excludedExceptions: excludedPasskeyExceptions,
      )
      ..listenSuccess(sendCoinsNotifierProvider, (transactionDetails) async {
        ref.invalidate(walletViewsDataNotifierProvider);

        // Since we will update wallet views after transfer, some old broadcasted transfers can be
        // confirmed, so we need to update their status to avoid applying balance hack twice
        final service = await ref.read(syncTransactionsServiceProvider.future);
        unawaited(
          ref
              .read(walletViewsDataNotifierProvider.future)
              .then((_) => service.syncBroadcastedTransfers()),
        );

        if (context.mounted && transactionDetails != null) {
          unawaited(context.push(successRouteLocationBuilder(
            transactionDetails.walletViewId,
            transactionDetails.txHash,
          ),),);
        }
      });

    return SheetContent(
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0.s),
              child: NavigationAppBar.screen(
                title: Text(locale.wallet_send_coins),
                actions: const [
                  NavigationCloseButton(),
                ],
              ),
            ),
            ScreenSideOffset.small(
              child: Column(
                children: [
                  SizedBox(height: 16.0.s),
                  if (coin != null) ...[
                    TransactionAmountSummary(
                      amount: coin.amount,
                      currency: coin.coinsGroup.abbreviation,
                      usdAmount: coin.amountUSD,
                      icon: CoinIconWidget(
                        imageUrl: coin.coinsGroup.iconUrl,
                        type: WalletItemIconType.big(),
                      ),
                      transactionType: TransactionType.send,
                    ),
                    SizedBox(height: 16.0.s),
                  ],
                  TransactionParticipant(
                    address: formData.receiverAddress,
                    pubkey: formData.contactPubkey,
                  ),
                  if (formData.memo != null) ...[
                    SizedBox(height: 16.0.s),
                    ListItem.text(
                      title: Text(locale.wallet_memo),
                      value: formData.memo!,
                    ),
                  ],
                  SizedBox(height: 16.0.s),
                  if (formData.senderWallet?.address case final String address) ...[
                    ListItem.textWithIcon(
                      title: Text(locale.wallet_title),
                      value: formData.walletView!.name,
                      icon: Assets.svg.walletWalletblue.icon(
                        size: ScreenSideOffset.defaultSmallMargin,
                      ),
                      secondary: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text(
                          address,
                          textAlign: TextAlign.right,
                          style: context.theme.appTextThemes.caption3,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.0.s),
                  ],
                  if (coin != null) ...[
                    ListItem.textWithIcon(
                      title: Text(locale.wallet_asset),
                      value: coin.coinsGroup.abbreviation,
                      icon: CoinIconWidget(
                        imageUrl: coin.coinsGroup.iconUrl,
                        type: WalletItemIconType.small(),
                      ),
                    ),
                    SizedBox(height: 16.0.s),
                  ],
                  if (formData.network case final NetworkData network) ...[
                    ListItem.textWithIcon(
                      title: Text(locale.wallet_network),
                      value: network.displayName,
                      icon: NetworkIconWidget(
                        type: WalletItemIconType.small(),
                        imageUrl: network.image,
                      ),
                    ),
                    SizedBox(height: 16.0.s),
                  ],
                  if (formData.selectedNetworkFeeOption case final NetworkFeeOption fee) ...[
                    if (fee.getDisplayArrivalTime(context) case final String arrivalTime)
                      ListItemArrivalTime(formattedTime: arrivalTime),
                    SizedBox(height: 16.0.s),
                    ListItemNetworkFee(value: formatCrypto(fee.amount, fee.symbol)),
                  ],
                  SizedBox(height: 22.0.s),
                  if (formData.assetData case final CoinAssetToSendData coin)
                    Button(
                      mainAxisSize: MainAxisSize.max,
                      disabled: ref.watch(sendCoinsNotifierProvider).isLoading,
                      label: ref.watch(sendCoinsNotifierProvider).maybeMap(
                            loading: (_) => const IONLoadingIndicator(),
                            orElse: () => Text(
                              '${locale.button_confirm} - ${formatToCurrency(coin.amountUSD)}',
                            ),
                          ),
                      onPressed: () async {
                        if (formData.assetData is! CoinAssetToSendData) return;

                        await guardPasskeyDialog(
                          ref.context,
                          (child) {
                            return RiverpodVerifyIdentityRequestBuilder(
                              provider: sendCoinsNotifierProvider,
                              requestWithVerifyIdentity: (
                                OnVerifyIdentity<Map<String, dynamic>> onVerifyIdentity,
                              ) async {
                                await ref
                                    .read(sendCoinsNotifierProvider.notifier)
                                    .send(onVerifyIdentity);
                              },
                              child: child,
                            );
                          },
                        );
                      },
                    ),
                  SizedBox(height: 16.0.s),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
