// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/status_bar/status_bar_color_wrapper.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/views/components/overlay_menu/own_entity_menu.dart';
import 'package:ion/app/features/feed/views/components/overlay_menu/user_info_menu.dart';
import 'package:ion/app/features/feed/views/pages/fullscreen_media/components/adaptive_media_view.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/soft_deletable_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/video/views/hooks/use_status_bar_color.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_back_button.dart';
import 'package:ion/generated/assets.gen.dart';

class FullscreenMediaPage extends HookConsumerWidget {
  const FullscreenMediaPage({
    required this.eventReference,
    required this.initialMediaIndex,
    this.framedEventReference,
    super.key,
  });

  final EventReference eventReference;
  final EventReference? framedEventReference;
  final int initialMediaIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useStatusBarColor();

    final isOwnedByCurrentUser =
        ref.watch(isCurrentUserSelectorProvider(eventReference.masterPubkey));

    final entity = ref.watch(ionConnectEntityProvider(eventReference: eventReference)).valueOrNull;

    final isDeleted = entity is SoftDeletableEntity && entity.isDeleted;

    return Material(
      color: Colors.transparent,
      child: StatusBarColorWrapper.light(
        child: Scaffold(
          backgroundColor: context.theme.appColors.primaryText,
          extendBodyBehindAppBar: true,
          appBar: NavigationAppBar.screen(
            backgroundColor: Colors.transparent,
            leading: NavigationBackButton(
              () => context.pop(),
              icon: Assets.svg.iconChatBack.icon(
                size: NavigationAppBar.actionButtonSide,
                color: context.theme.appColors.onPrimaryAccent,
                flipForRtl: true,
              ),
            ),
            onBackPress: () => context.pop(),
            actions: isDeleted
                ? null
                : [
                    Padding(
                      padding: EdgeInsetsDirectional.only(end: 6.0.s),
                      child: isOwnedByCurrentUser
                          ? OwnEntityMenu(
                              eventReference: eventReference,
                              iconColor: context.theme.appColors.onPrimaryAccent,
                              onDelete: () {
                                context.canPop();
                              },
                            )
                          : UserInfoMenu(
                              eventReference: eventReference,
                              iconColor: context.theme.appColors.onPrimaryAccent,
                            ),
                    ),
                  ],
          ),
          body: AdaptiveMediaView(
            eventReference: eventReference,
            initialMediaIndex: initialMediaIndex,
            framedEventReference: framedEventReference,
          ),
        ),
      ),
    );
  }
}
