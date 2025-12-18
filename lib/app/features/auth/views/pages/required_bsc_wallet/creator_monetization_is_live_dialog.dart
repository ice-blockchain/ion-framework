// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/wallets/providers/bsc_wallet_check_provider.m.dart';
import 'package:ion/app/features/wallets/providers/networks_provider.r.dart';
import 'package:ion/app/features/wallets/views/components/address_not_found_modal.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';
import 'package:ion/generated/assets.gen.dart';

class CreatorMonetizationIsLiveDialogEvent extends UiEvent {
  const CreatorMonetizationIsLiveDialogEvent();

  static bool shown = false;

  @override
  void performAction(BuildContext context) {
    if (!shown) {
      shown = true;
      showSimpleBottomSheet<void>(
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
    final isProcessing = useState(false);
    final pressed = useState(false);
    final bscWalletCheck = ref.watch(bscWalletCheckProvider);

    useOnInit(
      () {
        bscWalletCheck.whenData((result) {
          if (result.hasBscWallet && ref.context.mounted && pressed.value) {
            Navigator.of(ref.context).pop();
          }
        });
      },
      [bscWalletCheck, pressed.value],
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
                disabled: isProcessing.value,
                trailingIcon:
                    isProcessing.value ? const IONLoadingIndicator() : const SizedBox.shrink(),
                label: Text(context.i18n.bsc_required_dialog_action_button),
                onPressed: () async {
                  isProcessing.value = true;
                  pressed.value = true;
                  try {
                    final bscWalletCheck = await ref.watch(bscWalletCheckProvider.future);
                    if (!context.mounted) return;
                    if (!bscWalletCheck.hasBscWallet) {
                      final bscNetwork = bscWalletCheck.bscNetwork ??
                          (await ref.read(networksProvider.future))
                              .firstWhereOrNull((n) => n.isBsc);

                      if (!context.mounted || bscNetwork == null) return;

                      await showSimpleBottomSheet<void>(
                        context: context,
                        isDismissible: false,
                        child: AddressNotFoundModal(
                          isBottomSheet: true,
                          network: bscNetwork,
                          onWalletCreated: (_) {
                            // Close the AddressNotFoundModal sheet
                            if (ref.context.mounted) {
                              Navigator.of(ref.context).pop();
                            }
                            ref
                              ..invalidate(bscWalletCheckProvider)
                              ..invalidate(currentUserMetadataProvider);
                          },
                        ),
                      );
                    }
                  } finally {
                    isProcessing.value = false;
                  }
                },
              ),
              ScreenBottomOffset(),
            ],
          ),
        ),
      ],
    );
  }
}
