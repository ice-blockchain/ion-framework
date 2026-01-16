// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/avatar/avatar.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/gradient_border_painter/gradient_border_painter.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/mock.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/user_name_tile/user_name_tile.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';
import 'package:ion/generated/assets.gen.dart';

class CreatorTokenIsLiveDialogEvent extends UiEvent {
  CreatorTokenIsLiveDialogEvent(this.tokenDefinitionEventReference);

  static bool shown = false;
  final ReplaceableEventReference tokenDefinitionEventReference;

  @override
  void performAction(BuildContext context) {
    if (!shown) {
      shown = true;
      showSimpleBottomSheet<void>(
        context: context,
        backgroundColor: context.theme.appColors.forest,
        child:
            CreatorTokenIsLiveDialog(tokenDefinitionEventReference: tokenDefinitionEventReference),
      ).whenComplete(() => shown = false);
    }
  }
}

class CreatorTokenIsLiveDialog extends HookConsumerWidget {
  const CreatorTokenIsLiveDialog({required this.tokenDefinitionEventReference, super.key});

  final ReplaceableEventReference tokenDefinitionEventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarUrl = ref.watch(currentUserMetadataProvider).value?.data.avatarUrl;
    final imageColors = useImageColors(avatarUrl);

    return ProfileGradientBackground(
      colors: imageColors ?? useAvatarFallbackColors,
      disableDarkGradient: false,
      child: _ContentState(tokenDefinitionEventReference),
    );
  }
}

class _ContentState extends HookConsumerWidget {
  const _ContentState(this.tokenDefinitionEventReference);

  final ReplaceableEventReference tokenDefinitionEventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);
    final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider) ?? '';
    final userMetadata = ref.watch(currentUserMetadataProvider).valueOrNull;
    final avatarUrl = userMetadata?.data.avatarUrl ?? '';

    final eventReferenceString = userMetadata?.toEventReference().toString();

    final token = eventReferenceString != null
        ? ref.watch(tokenMarketInfoProvider(eventReferenceString)).valueOrNull
        : null;

    return Stack(
      children: [
        PositionedDirectional(
          bottom: 0,
          start: 0,
          end: 0,
          child: Assets.images.tokenizedCommunities.creatorMonetizationLiveRays
              .iconWithDimensions(width: 461.s, height: 461.s),
        ),
        PositionedDirectional(
          end: 8,
          child: NavigationCloseButton(color: context.theme.appColors.onPrimaryAccent),
        ),
        ScreenSideOffset.medium(
          child: Column(
            children: [
              SizedBox(height: 30.0.s),
              CustomPaint(
                painter: GradientBorderPainter(
                  strokeWidth: 2.0.s,
                  cornerRadius: 26.0.s,
                  gradient: storyBorderGradients[3],
                  backgroundColor: context.theme.appColors.forest.withAlpha(125),
                ),
                child: Padding(
                  padding: EdgeInsets.all(18.0.s),
                  child: Avatar(
                    size: 64.0.s,
                    fit: BoxFit.cover,
                    imageUrl: avatarUrl,
                    borderRadius: BorderRadius.all(Radius.circular(16.0.s)),
                  ),
                ),
              ),
              SizedBox(height: 8.0.s),
              UserNameTile(
                showProfileTokenPrice: true,
                profileMode: ProfileMode.dark,
                pubkey: currentUserMasterPubkey,
                priceUsd: token?.marketData.priceUSD,
              ),
              SizedBox(height: 18.0.s),
              Text(
                context.i18n.tokenized_community_creator_token_live_title,
                textAlign: TextAlign.center,
                style: context.theme.appTextThemes.title
                    .copyWith(color: context.theme.appColors.onPrimaryAccent),
              ),
              SizedBox(height: 8.0.s),
              Text(
                context.i18n.tokenized_community_creator_token_live_subtitle,
                textAlign: TextAlign.center,
                style: context.theme.appTextThemes.body2
                    .copyWith(color: context.theme.appColors.secondaryBackground),
              ),
              SizedBox(height: 24.0.s),
              Button(
                disabled: isLoading.value,
                label: Text(context.i18n.button_share),
                minimumSize: Size(double.infinity, 56.0.s),
                trailingIcon:
                    isLoading.value ? const IONLoadingIndicator() : const SizedBox.shrink(),
                onPressed: token != null
                    ? () async {
                        isLoading.value = true;
                        try {
                          if (context.mounted) {
                            context.pop();

                            await ShareViaMessageModalRoute(
                              eventReference: tokenDefinitionEventReference.encode(),
                            ).push<void>(context);
                          }
                        } catch (e, st) {
                          Logger.error(e, stackTrace: st);
                        } finally {
                          isLoading.value = false;
                        }
                      }
                    : null,
              ),
              ScreenBottomOffset(),
            ],
          ),
        ),
      ],
    );
  }
}
