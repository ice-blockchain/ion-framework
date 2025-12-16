// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/verify_identity/verify_identity_prompt_dialog_helper.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/wallets/providers/bsc_wallet_check_provider.m.dart';
import 'package:ion/app/features/wallets/providers/networks_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/receive_coins/providers/wallet_address_notifier_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_identity_client/ion_identity.dart';

class RequiredBscWalletDialog extends HookConsumerWidget {
  const RequiredBscWalletDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bscWalletCheck = ref.watch(bscWalletCheckProvider);

    useOnInit(
      () {
        bscWalletCheck.whenData((result) {
          if (result.hasBscWallet && ref.context.mounted) {
            Navigator.of(ref.context).pop();
          }
        });
      },
      [bscWalletCheck],
    );

    final isCreatingWallet = ref.watch(
      walletAddressNotifierProvider.select((state) => state.isLoading),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NavigationAppBar.modal(
          title: Text(context.i18n.bsc_setup_dialog_header),
          actions: const [
            NavigationCloseButton(),
          ],
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(start: 30.0.s, end: 30.0.s, top: 22.0.s),
          child: InfoCard(
            iconAsset: Assets.svg.actionWalletSetupbnb,
            title: context.i18n.bsc_setup_dialog_title,
            description: context.i18n.bsc_setup_dialog_desc,
          ),
        ),
        SizedBox(height: 22.0.s),
        ScreenSideOffset.small(
          child: Button(
            mainAxisSize: MainAxisSize.max,
            disabled: isCreatingWallet,
            trailingIcon: isCreatingWallet ? const IONLoadingIndicator() : const SizedBox.shrink(),
            leadingIcon:
                Assets.svg.iconPostAddanswer.icon(color: context.theme.appColors.onPrimaryAccent),
            label: Text(context.i18n.bsc_setup_dialog_action),
            onPressed: () => _createBscWallet(ref),
          ),
        ),
        ScreenBottomOffset(),
      ],
    );
  }

  Future<void> _createBscWallet(WidgetRef ref) async {
    final bscWalletCheck = ref.read(bscWalletCheckProvider);
    final network = bscWalletCheck.value?.bscNetwork ??
        (await ref.read(networksProvider.future)).firstWhereOrNull((n) => n.isBsc);

    if (network == null || !ref.context.mounted) return;

    String? address;
    await guardPasskeyDialog(
      ref.context,
      (child) {
        return RiverpodVerifyIdentityRequestBuilder(
          provider: walletAddressNotifierProvider,
          requestWithVerifyIdentity: (OnVerifyIdentity<Wallet> onVerifyIdentity) async {
            address = await ref.read(walletAddressNotifierProvider.notifier).createWallet(
                  onVerifyIdentity: onVerifyIdentity,
                  network: network,
                );
          },
          child: child,
        );
      },
    );

    if (address != null && ref.context.mounted) {
      _invalidateWalletProviders(ref);
    }
  }

  void _invalidateWalletProviders(WidgetRef ref) {
    ref
      ..invalidate(bscWalletCheckProvider)
      ..invalidate(currentUserMetadataProvider);
  }
}
