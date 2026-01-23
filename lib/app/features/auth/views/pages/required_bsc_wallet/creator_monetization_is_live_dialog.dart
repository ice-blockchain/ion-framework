// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/verify_identity/verify_identity_prompt_dialog_helper.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/providers/bsc_wallet_check_provider.m.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/receive_coins/providers/wallet_address_notifier_provider.r.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_identity_client/ion_identity.dart';

class CreatorMonetizationIsLiveDialogEvent extends UiEvent {
  const CreatorMonetizationIsLiveDialogEvent() : super(id: 'creator_monetization_is_live_dialog');

  static bool shown = false;

  @override
  Future<void> performAction(BuildContext context) async {
    if (!shown) {
      shown = true;
      await showSimpleBottomSheet<void>(
        context: context,
        isDismissible: false,
        backgroundColor: context.theme.appColors.forest,
        child: const CreatorMonetizationIsLiveDialog(),
      ).whenComplete(() => shown = false);
    }
  }
}

class CreatorMonetizationIsLiveDialog extends HookConsumerWidget {
  const CreatorMonetizationIsLiveDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarUrl = ref.watch(currentUserMetadataProvider).value?.data.avatarUrl;
    final imageColors = useImageColors(avatarUrl);

    return ProfileGradientBackground(
      colors: imageColors ?? useAvatarFallbackColors,
      disableDarkGradient: false,
      child: const _ContentState(),
    );
  }
}

class _ContentState extends ConsumerWidget {
  const _ContentState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textStyles = context.theme.appTextThemes;
    final colors = context.theme.appColors;

    final isCreatingWallet = ref.watch(
      walletAddressNotifierProvider.select((state) => state.isLoading),
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.scale(
          scale: 1.5,
          child: SvgPicture.asset(Assets.images.tokenizedCommunities.creatorMonetizationLiveRays),
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
                onPressed: () => _onActionPressed(context, ref),
              ),
              ScreenBottomOffset(),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onActionPressed(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(bscWalletCheckProvider.future);
    if (!context.mounted) return;

    if (result.hasBscWallet) {
      Navigator.of(context).pop();
      return;
    }

    final bscNetwork = result.bscNetwork;
    if (bscNetwork == null) return;

    final address = await _createBscWallet(context, ref, network: bscNetwork);
    if (!context.mounted || address == null) return;

    await ref
        .read(userMetadataInvalidatorNotifierProvider.notifier)
        .invalidateCurrentUserMetadataProviders();
    if (!context.mounted) return;

    Navigator.of(context).pop();
  }

  Future<String?> _createBscWallet(
    BuildContext context,
    WidgetRef ref, {
    required NetworkData network,
  }) async {
    String? address;
    await guardPasskeyDialog(
      context,
      (child) {
        return RiverpodVerifyIdentityRequestBuilder<void, Wallet>(
          provider: walletAddressNotifierProvider,
          requestWithVerifyIdentity: (OnVerifyIdentity<Wallet> onVerifyIdentity) async {
            address = await ref.read(walletAddressNotifierProvider.notifier).createWallet(
                  network: network,
                  onVerifyIdentity: onVerifyIdentity,
                );
          },
          child: child,
        );
      },
    );

    return address;
  }
}
