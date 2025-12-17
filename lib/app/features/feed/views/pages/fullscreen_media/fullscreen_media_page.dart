// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/bottom_sheet_menu/bottom_sheet_menu_button.dart';
import 'package:ion/app/components/status_bar/status_bar_color_wrapper.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/views/components/bottom_sheet_menu/own_post_menu_bottom_sheet.dart';
import 'package:ion/app/features/feed/views/components/bottom_sheet_menu/post_menu_bottom_sheet.dart';
import 'package:ion/app/features/feed/views/pages/fullscreen_media/components/adaptive_media_view.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/soft_deletable_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_action_first_buy_provider.r.dart';
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

    final isEntityDeleted = entity is SoftDeletableEntity && entity.isDeleted;
    final hasFirstBuy = _hasFirstBuy(ref, isOwnedByCurrentUser, entity);
    final isEditable = switch (entity) {
      final ModifiablePostEntity post =>
        post.data.editingEndedAt?.value.toDateTime.isAfter(DateTime.now()) ?? false,
      _ => false,
    };
    final shouldShowMenuButton = !isOwnedByCurrentUser || !(hasFirstBuy && !isEditable);

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
              showShadow: true,
              icon: Assets.svg.iconChatBack.icon(
                size: NavigationAppBar.actionButtonSide,
                color: context.theme.appColors.onPrimaryAccent,
                flipForRtl: true,
              ),
            ),
            onBackPress: () => context.pop(),
            actions: isEntityDeleted
                ? null
                : shouldShowMenuButton
                    ? [
                        Padding(
                          padding: EdgeInsetsDirectional.only(end: 6.0.s),
                          child: isOwnedByCurrentUser
                              ? BottomSheetMenuButton(
                                  showShadow: true,
                                  iconColor: context.theme.appColors.onPrimaryAccent,
                                  menuBuilder: (context) => OwnPostMenuBottomSheet(
                                    eventReference: eventReference,
                                    onDelete: () {
                                      context.canPop();
                                    },
                                  ),
                                )
                              : BottomSheetMenuButton(
                                  showShadow: true,
                                  iconColor: context.theme.appColors.onPrimaryAccent,
                                  menuBuilder: (context) => PostMenuBottomSheet(
                                    eventReference: eventReference,
                                  ),
                                ),
                        ),
                      ]
                    : [],
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

  bool _hasFirstBuy(
    WidgetRef ref,
    bool isOwnedByCurrentUser,
    IonConnectEntity? entity,
  ) {
    if (!isOwnedByCurrentUser || entity == null) return false;
    final eventReference = entity.toEventReference();
    return ref
            .watch(
              ionConnectEntityHasTokenProvider(eventReference: eventReference),
            )
            .valueOrNull ??
        false;
  }
}
