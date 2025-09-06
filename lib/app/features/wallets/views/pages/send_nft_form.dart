// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/extensions/object.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/providers/send_nft_form_provider.r.dart';
import 'package:ion/app/features/wallets/utils/wallet_address_validator.dart';
import 'package:ion/app/features/wallets/views/components/nft_name.dart';
import 'package:ion/app/features/wallets/views/components/nft_picture.dart';
import 'package:ion/app/features/wallets/views/components/not_enough_coins_for_network_fee_message.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/send_coins/components/contact_input_switcher.dart';
import 'package:ion/app/features/wallets/views/pages/send_nft/components/nft_network_fee_selector.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class SendNftForm extends HookConsumerWidget {
  const SendNftForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;
    final locale = context.i18n;

    final formController = ref.watch(sendNftFormControllerProvider);
    final notifier = ref.watch(sendNftFormControllerProvider.notifier);
    final selectedNft = formController.nft!;
    final selectedContactPubkey = formController.contactPubkey;

    final addressValidator = useMemoized(
      () => WalletAddressValidator(formController.nft?.network.id ?? ''),
      [formController.nft?.network.id],
    );

    final isContinueButtonEnabled = selectedContactPubkey != null ||
        (formController.receiverAddress.isNotEmpty &&
            addressValidator.validate(formController.receiverAddress));

    final feeSpacer = SizedBox(height: 17.s);

    return SheetContent(
      backgroundColor: colors.secondaryBackground,
      body: KeyboardDismissOnTap(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.s),
                child: NavigationAppBar.screen(
                  title: Text(locale.send_nft_title),
                  actions: const [
                    NavigationCloseButton(),
                  ],
                ),
              ),
              ScreenSideOffset.small(
                child: Column(
                  children: [
                    NftPicture(
                      imageUrl: selectedNft.imageUrl,
                    ),
                    SizedBox(height: 16.s),
                    NftName(
                      rank: selectedNft.tokenId,
                      name: selectedNft.name,
                    ),
                    SizedBox(height: 16.s),
                    ContactInputSwitcher(
                      pubkey: selectedContactPubkey,
                      address: formController.receiverAddress,
                      network: selectedNft.network,
                      onWalletAddressChanged: (value) {
                        if (value != null && value.isNotEmpty) {
                          notifier.setReceiverAddress(value);
                        }
                      },
                      onClearTap: (pubkey) {
                        notifier
                          ..setContact(null)
                          ..setReceiverAddress('');
                      },
                      onContactTap: () async {
                        final pubkey = await NftSelectContactRoute(
                          networkId: selectedNft.network.id,
                        ).push<String>(context);

                        pubkey?.let(notifier.setContact);
                      },
                      onScanPressed: () async {
                        final address = await NftSendScanRoute().push<String?>(context);
                        if (address != null) {
                          notifier.setReceiverAddress(address);
                        }
                      },
                    ),
                    feeSpacer,
                    const NftNetworkFeeSelector(),
                    if (formController.canCoverNetworkFee)
                      feeSpacer
                    else if (selectedNft.network case final NetworkData network)
                      NotEnoughMoneyForNetworkFeeMessage(
                        network: network,
                        placeholder: feeSpacer,
                      ),
                    SizedBox(height: 24.s),
                    Button(
                      label: Text(locale.button_continue),
                      mainAxisSize: MainAxisSize.max,
                      disabled: !isContinueButtonEnabled,
                      type: isContinueButtonEnabled ? ButtonType.primary : ButtonType.disabled,
                      trailingIcon: Assets.svg.iconButtonNext.icon(color: colors.primaryBackground),
                      onPressed: () {
                        SendNftConfirmRoute().push<void>(context);
                      },
                    ),
                    SizedBox(height: 16.s),
                  ],
                ),
              ),
              ScreenBottomOffset(),
            ],
          ),
        ),
      ),
    );
  }
}
