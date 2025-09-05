// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/icons/network_icon_widget.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/verify_identity/verify_identity_prompt_dialog_helper.dart';
import 'package:ion/app/features/wallets/model/network_fee_option.f.dart';
import 'package:ion/app/features/wallets/providers/send_nft_form_provider.r.dart';
import 'package:ion/app/features/wallets/providers/send_nft_notifier_provider.r.dart';
import 'package:ion/app/features/wallets/views/components/arrival_time/list_item_arrival_time.dart';
import 'package:ion/app/features/wallets/views/components/network_fee/list_item_network_fee.dart';
import 'package:ion/app/features/wallets/views/components/nft_item.dart';
import 'package:ion/app/features/wallets/views/components/transaction_participant.dart';
import 'package:ion/app/features/wallets/views/utils/crypto_formatter.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_identity_client/ion_identity.dart';

class SendNftConfirmPage extends ConsumerWidget {
  const SendNftConfirmPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = context.i18n;
    final formData = ref.watch(sendNftFormControllerProvider);
    final nft = formData.nft!;

    ref
      ..displayErrors(
        sendNftNotifierProvider,
        excludedExceptions: excludedPasskeyExceptions,
      )
      ..listenSuccess(sendNftNotifierProvider, (transactionDetails) {
        if (context.mounted && transactionDetails != null) {
          NftTransactionResultRoute(
            walletViewId: transactionDetails.walletViewId,
            txHash: transactionDetails.txHash,
          ).go(context);
        }
      });

    return SheetContent(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationAppBar.modal(
            title: Text(context.i18n.send_nft_navigation_title),
            actions: const [NavigationCloseButton()],
          ),
          ScreenSideOffset.small(
            child: SingleChildScrollView(
              padding: EdgeInsetsDirectional.only(top: 10.0.s),
              child: Column(
                children: [
                  NftItem(nftData: nft, showNetwork: false),
                  SizedBox(height: 16.0.s),
                  TransactionParticipant(
                    address: formData.receiverAddress,
                    pubkey: formData.contactPubkey,
                  ),
                  SizedBox(height: 12.0.s),
                  ListItem.textWithIcon(
                    title: Text(locale.wallet_title),
                    value: formData.walletView!.name,
                    icon: Assets.svg.walletWalletblue.icon(
                      size: ScreenSideOffset.defaultSmallMargin,
                    ),
                    secondary: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        formData.senderWallet!.address!,
                        textAlign: TextAlign.right,
                        style: context.theme.appTextThemes.caption3,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.0.s),
                  ListItem.textWithIcon(
                    title: Text(context.i18n.send_nft_confirm_network),
                    value: nft.network.displayName,
                    icon: NetworkIconWidget(
                      type: WalletItemIconType.small(),
                      imageUrl: nft.network.image,
                    ),
                  ),
                  SizedBox(height: 12.0.s),
                  if (formData.selectedNetworkFeeOption case final NetworkFeeOption fee) ...[
                    if (fee.getDisplayArrivalTime(context) case final String arrivalTime) ...[
                      ListItemArrivalTime(formattedTime: arrivalTime),
                      SizedBox(height: 12.0.s),
                    ],
                    ListItemNetworkFee(
                      value: formatCrypto(fee.amount, fee.symbol),
                    ),
                  ],
                  SizedBox(height: 12.0.s),
                  if (formData.nft != null)
                    Button(
                      mainAxisSize: MainAxisSize.max,
                      disabled: ref.watch(sendNftNotifierProvider).isLoading,
                      label: ref.watch(sendNftNotifierProvider).maybeMap(
                            loading: (_) => const IONLoadingIndicator(),
                            orElse: () => Text(locale.button_confirm),
                          ),
                      onPressed: () async {
                        await guardPasskeyDialog(
                          ref.context,
                          (child) {
                            return RiverpodVerifyIdentityRequestBuilder(
                              provider: sendNftNotifierProvider,
                              requestWithVerifyIdentity: (
                                OnVerifyIdentity<Map<String, dynamic>> onVerifyIdentity,
                              ) async {
                                await ref
                                    .read(sendNftNotifierProvider.notifier)
                                    .send(onVerifyIdentity);
                              },
                              child: child,
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          ScreenBottomOffset(),
        ],
      ),
    );
  }
}
