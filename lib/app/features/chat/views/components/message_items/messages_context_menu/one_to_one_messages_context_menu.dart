// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/overlay_menu/components/overlay_menu_item.dart';
import 'package:ion/app/components/overlay_menu/components/overlay_menu_item_separator.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu_container.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/providers/muted_conversations_provider.r.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/block_user_modal/block_user_modal.dart';
import 'package:ion/app/features/user/providers/report_notifier.m.dart';
import 'package:ion/app/features/user_block/optimistic_ui/block_user_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';

class OneToOneMessagingContextMenu extends ConsumerWidget {
  const OneToOneMessagingContextMenu({
    required this.isBlocked,
    required this.conversationId,
    required this.receiverMasterPubkey,
    super.key,
    this.onToggleMute,
  });

  final bool isBlocked;
  final String conversationId;
  final VoidCallback? onToggleMute;
  final String receiverMasterPubkey;
  static double get iconSize => 20.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMuted =
        ref.watch(mutedConversationsProvider).valueOrNull?.contains(conversationId) ?? false;

    ref.displayErrors(reportNotifierProvider);

    return OverlayMenu(
      menuBuilder: (closeMenu) => Column(
        children: [
          OverlayMenuContainer(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0.s),
              child: Column(
                children: [
                  OverlayMenuItem(
                    label: isMuted ? context.i18n.button_unmute : context.i18n.button_mute,
                    icon: isMuted
                        ? Assets.svg.iconChannelUnmute
                            .icon(size: iconSize, color: context.theme.appColors.quaternaryText)
                        : Assets.svg.iconChannelMute
                            .icon(size: iconSize, color: context.theme.appColors.quaternaryText),
                    onPressed: () {
                      closeMenu();
                      onToggleMute?.call();
                    },
                  ),
                  const OverlayMenuItemSeparator(),
                  OverlayMenuItem(
                    label: isBlocked ? context.i18n.button_unblock : context.i18n.button_block,
                    icon: Assets.svg.iconPhofileBlockuser
                        .icon(size: iconSize, color: context.theme.appColors.quaternaryText),
                    onPressed: () async {
                      closeMenu();

                      if (!isBlocked) {
                        await showSimpleBottomSheet<void>(
                          context: context,
                          child: BlockUserModal(pubkey: receiverMasterPubkey),
                        );
                      } else {
                        await ref
                            .read(toggleBlockNotifierProvider.notifier)
                            .toggle(receiverMasterPubkey);
                      }
                    },
                  ),
                  const OverlayMenuItemSeparator(),
                  OverlayMenuItem(
                    label: context.i18n.button_delete,
                    labelColor: context.theme.appColors.attentionRed,
                    icon: Assets.svg.iconBlockDelete
                        .icon(size: iconSize, color: context.theme.appColors.attentionRed),
                    onPressed: () async {
                      closeMenu();
                      final deleted = await DeleteConversationRoute(
                            conversationIds: [conversationId],
                          ).push<bool>(context) ??
                          false;

                      if (deleted && context.mounted) {
                        context.pop();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      child: Assets.svg.iconMorePopup.icon(
        color: context.theme.appColors.onTertiaryBackground,
      ),
    );
  }
}
