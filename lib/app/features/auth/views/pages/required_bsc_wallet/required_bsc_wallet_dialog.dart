// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/verify_identity/verify_identity_prompt_dialog_helper.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/wallets/providers/bsc_wallet_check_provider.m.dart';
import 'package:ion/app/features/wallets/providers/networks_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/receive_coins/providers/wallet_address_notifier_provider.r.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_identity_client/ion_identity.dart';

class ShowRequiredBscWalletDialogEvent extends UiEvent {
  const ShowRequiredBscWalletDialogEvent();

  @override
  void performAction(BuildContext context) {
    showSimpleBottomSheet<void>(
      context: context,
      isDismissible: false,
      backgroundColor: context.theme.appColors.forest,
      child: const RequiredBscWalletDialog(),
    );
  }
}

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

    return ProfileGradientBackground(
      colors: useAvatarFallbackColors,
      disableDarkGradient: false,
      child: const _ContentState(),
    );
  }
}

class _ContentState extends HookConsumerWidget {
  const _ContentState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textStyles = context.theme.appTextThemes;
    final colors = context.theme.appColors;
    final isCreatingWallet = ref.watch(
      walletAddressNotifierProvider.select((state) => state.isLoading),
    );

    return Stack(
      children: [
        PositionedDirectional(
          bottom: 0,
          start: 0,
          end: 0,
          child: Assets.images.tokenizedCommunities.creatorMonetizationLiveRays
              .iconWithDimensions(width: 461.s, height: 461.s),
        ),
        ScreenSideOffset.medium(
          child: Column(
            children: [
              SizedBox(height: 30.0.s),
              Assets.images.tokenizedCommunities.creatorMonetizationLive.iconWithDimensions(
                width: 160.s,
                height: 130.s,
              ),
              SizedBox(height: 14.0.s),
              Text(
                context.i18n.bsc_required_dialog_title,
                style: textStyles.title.copyWith(color: colors.onPrimaryAccent),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.0.s),
              Text(
                context.i18n.bsc_required_dialog_description,
                style: textStyles.body2.copyWith(color: colors.secondaryBackground),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 21.0.s),
              Button(
                minimumSize: Size(double.infinity, 56.0.s),
                disabled: isCreatingWallet,
                trailingIcon:
                    isCreatingWallet ? const IONLoadingIndicator() : const SizedBox.shrink(),
                label: Text(context.i18n.bsc_required_dialog_action_button),
                onPressed: () => _createBscWallet(ref),
              ),
              ScreenBottomOffset(),
            ],
          ),
        ),
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
