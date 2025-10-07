// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/select/select_coin_button.dart';
import 'package:ion/app/components/select/select_network_button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/extensions/object.dart';
import 'package:ion/app/features/user/pages/profile_page/components/user_payment_flow_card/user_payment_flow_card.dart';
import 'package:ion/app/features/wallets/model/crypto_asset_to_send_data.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/providers/send_asset_form_provider.r.dart';
import 'package:ion/app/features/wallets/utils/wallet_address_validator.dart';
import 'package:ion/app/features/wallets/views/components/not_enough_coins_for_network_fee_message.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/send_coins/components/coin_amount_input.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/send_coins/components/coins_network_fee_selector.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/send_coins/components/contact_input_switcher.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/send_coins/components/memo_input_field.dart';
import 'package:ion/app/features/wallets/views/utils/amount_parser.dart';
import 'package:ion/app/features/wallets/views/utils/crypto_formatter.dart';
import 'package:ion/app/features/wallets/views/utils/network_validator.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class SendCoinsForm extends HookConsumerWidget {
  const SendCoinsForm({
    required this.selectCoinRouteLocationBuilder,
    required this.selectNetworkRouteLocationBuilder,
    required this.confirmRouteLocationBuilder,
    this.scanAddressRouteLocationBuilder,
    this.selectContactRouteLocationBuilder,
    super.key,
  });

  final String Function() selectCoinRouteLocationBuilder;
  final String Function() selectNetworkRouteLocationBuilder;
  final String Function(String networkId)? selectContactRouteLocationBuilder;
  final String Function()? scanAddressRouteLocationBuilder;
  final String Function() confirmRouteLocationBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;
    final locale = context.i18n;

    final formController = ref.watch(sendAssetFormControllerProvider);
    final notifier = ref.watch(sendAssetFormControllerProvider.notifier);
    final selectedContactPubkey = formController.contactPubkey;
    final coin = formController.assetData.as<CoinAssetToSendData>();
    final maxAmount = coin?.selectedOption?.amount ?? 0;
    final exceedsMaxAmount = formController.exceedsMaxAmount;

    final amount = coin?.amount ?? 0.0;
    final amountController = useTextEditingController();
    final usdAmount =
        (parseAmount(amountController.text) ?? 0) * (coin?.selectedOption?.coin.priceUSD ?? 0);

    useOnInit(() => amountController.text = amount == 0.0 ? '' : formatCrypto(amount), []);

    if (formController.isContactPreselected) {
      _listenContactWallet(ref, formController.contactPubkey);
    }

    useOnInit(
      () {
        void listener() {
          final numValue = parseAmount(amountController.value.text);
          final isValidAmount = numValue != null && numValue <= maxAmount && numValue > 0;
          notifier.setCoinsAmount(isValidAmount ? amountController.text : '');
        }

        amountController.addListener(listener);
      },
      [amountController],
    );

    final validAmount = formController.assetData.maybeMap(
      coin: (coin) => coin.amount > 0,
      orElse: () => false,
    );

    final network = useRef(formController.network);
    final validator = useRef(WalletAddressValidator(network.value?.id ?? ''));

    final isContinueButtonEnabled = formController.canCoverNetworkFee &&
        validAmount &&
        formController.senderWallet?.address != null &&
        validator.value.validate(formController.receiverAddress) &&
        !exceedsMaxAmount;

    final feeSectionSpacing = SizedBox(height: 20.0.s);
    final isContactSelected =
        formController.isContactPreselected && formController.contactPubkey != null;
    final isMemoAvailable =
        (network.value?.isMemoSupported ?? false) && formController.contactPubkey == null;

    return SheetContent(
      body: KeyboardDismissOnTap(
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
            Flexible(
              child: SingleChildScrollView(
                child: ScreenSideOffset.small(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SelectCoinButton(
                        selectedCoin: coin?.selectedOption,
                        enabled: formController.request == null,
                        onTap: () => context.push(selectCoinRouteLocationBuilder()),
                      ),
                      SizedBox(height: 12.0.s),
                      SelectNetworkButton(
                        selectedNetwork: formController.network,
                        enabled: formController.request == null,
                        onTap: () {
                          if (coin?.selectedOption != null) {
                            context.push(selectNetworkRouteLocationBuilder());
                          } else {
                            context.push(selectCoinRouteLocationBuilder());
                          }
                        },
                      ),
                      SizedBox(height: 12.0.s),
                      if (isContactSelected)
                        UserPaymentFlowCard(pubkey: formController.contactPubkey!)
                      else
                        ContactInputSwitcher(
                          pubkey: selectedContactPubkey,
                          address: formController.receiverAddress,
                          network: formController.network,
                          onClearTap: (pubkey) {
                            notifier
                              ..setContact(null)
                              ..setReceiverAddress('');
                          },
                          onWalletAddressChanged: (String? value) {
                            if (value != null) {
                              notifier.setReceiverAddress(value);
                            }
                          },
                          onContactTap: () async {
                            final pubkey = await context.push<String>(
                              selectContactRouteLocationBuilder!(formController.network!.id),
                            );

                            if (pubkey != null) notifier.setContact(pubkey);
                          },
                          onScanPressed: () async {
                            final address = await context.push<String?>(
                              scanAddressRouteLocationBuilder!(),
                            );
                            if (address != null) {
                              notifier.setReceiverAddress(address);
                            }
                          },
                        ),
                      if (isMemoAvailable) ...[
                        SizedBox(height: 12.0.s),
                        MemoInputField(
                          onMemoChanged: notifier.setMemo,
                          memo: formController.memo,
                        ),
                      ],
                      SizedBox(height: 12.0.s),
                      CoinAmountInput(
                        controller: amountController,
                        maxValue: coin?.selectedOption?.amount ?? 0,
                        coin: coin?.selectedOption?.coin,
                        balanceUSD: usdAmount,
                        errorText:
                            exceedsMaxAmount ? locale.wallet_coin_amount_insufficient_funds : null,
                      ),
                      CoinsNetworkFeeSelector(
                        padding: EdgeInsetsDirectional.only(top: 17.0.s),
                      ),
                      if (formController.canCoverNetworkFee)
                        feeSectionSpacing
                      else if (formController.network case final NetworkData network)
                        NotEnoughMoneyForNetworkFeeMessage(
                          network: network,
                          placeholder: feeSectionSpacing,
                        ),
                      ScreenBottomOffset(
                        child: Button(
                          label: Text(
                            locale.button_continue,
                          ),
                          type: isContinueButtonEnabled ? ButtonType.primary : ButtonType.disabled,
                          mainAxisSize: MainAxisSize.max,
                          disabled: !isContinueButtonEnabled,
                          trailingIcon: Assets.svg.iconButtonNext.icon(
                            color: colors.primaryBackground,
                          ),
                          onPressed: () => context.push(confirmRouteLocationBuilder()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _listenContactWallet(WidgetRef ref, String? contactPubkey) async {
    if (contactPubkey == null) {
      return;
    }

    ref.listen(
      sendAssetFormControllerProvider.select((formState) => formState.network),
      (_, network) {
        if (network == null) {
          return;
        }

        checkWalletExists(ref, contactPubkey, network);
      },
    );
  }
}
