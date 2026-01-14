// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';
import 'package:ion/generated/assets.gen.dart';

class TokenizedCommunityOnboardingDialogEvent extends UiEvent {
  const TokenizedCommunityOnboardingDialogEvent()
      : super(id: 'tokenized_community_onboarding_dialog');

  static bool shown = false;

  @override
  Future<void> performAction(BuildContext context) async {
    //TODO:uncomment
    // if (!shown) {
    shown = true;
    await showSimpleBottomSheet<void>(
      context: context,
      isDismissible: false,
      backgroundColor: context.theme.appColors.forest,
      child: const TokenizedCommunityOnboardingDialog(),
    ).whenComplete(() => shown = false);
    // }
  }
}

class TokenizedCommunityOnboardingDialog extends HookConsumerWidget {
  const TokenizedCommunityOnboardingDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProfileGradientBackground(
      colors: useAvatarFallbackColors,
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
                label: const Text('onboarding'),
                onPressed: () => context.pop(),
              ),
              ScreenBottomOffset(),
            ],
          ),
        ),
      ],
    );
  }
}
