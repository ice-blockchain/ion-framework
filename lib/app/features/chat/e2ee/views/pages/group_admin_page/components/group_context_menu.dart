// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/overlay_menu/notifiers/overlay_menu_close_signal.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu_container.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/encrypted_group_message_entity.f.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/group_member_role.f.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/providers/conversation_messages_provider.r.dart';
import 'package:ion/app/features/chat/providers/muted_conversations_provider.r.dart';
import 'package:ion/app/features/user/pages/components/header_action/header_action.dart';
import 'package:ion/app/features/user/pages/profile_page/components/header/context_menu_item.dart';
import 'package:ion/app/features/user/pages/profile_page/components/header/context_menu_item_divider.dart';
import 'package:ion/app/features/user/providers/report_notifier.m.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class GroupContextMenu extends HookConsumerWidget {
  const GroupContextMenu({
    required this.conversationId,
    required this.closeSignal,
    required this.currentUserRole,
    super.key,
  });

  final String conversationId;
  final OverlayMenuCloseSignal closeSignal;
  final GroupMemberRole? currentUserRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final closeMenuRef = useRef<CloseOverlayMenuCallback?>(null);
    useEffect(
      () {
        void listener() => closeMenuRef.value?.call(animate: false);

        closeSignal.addListener(listener);

        return () => closeSignal.removeListener(listener);
      },
      [closeSignal],
    );

    return OverlayMenu(
      menuBuilder: (closeMenu) {
        closeMenuRef.value = closeMenu;

        final menuItems = _buildMenuItems(
          context,
          ref,
          closeMenu,
        ).toList();
        return OverlayMenuContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: menuItems,
          ),
        );
      },
      child: HeaderAction(
        onPressed: () {},
        disabled: true,
        opacity: 1,
        assetName: Assets.svg.iconMorePopup,
      ),
    );
  }

  Iterable<Widget> _buildMenuItems(
    BuildContext context,
    WidgetRef ref,
    VoidCallback closeMenu,
  ) {
    final isOwnerOrAdmin = currentUserRole != null &&
        (currentUserRole is GroupMemberRoleOwner || currentUserRole is GroupMemberRoleAdmin);

    final isMuted =
        ref.watch(mutedConversationIdsProvider).valueOrNull?.contains(conversationId) ?? false;

    final menuItems = <Widget>[
      ContextMenuItem(
        label: isMuted ? context.i18n.button_unmute : context.i18n.button_mute,
        iconAsset: isMuted ? Assets.svg.iconChannelUnmute : Assets.svg.iconChannelMute,
        onPressed: () {
          closeMenu();
          // TODO: Toggle mute for group
        },
      ),
      const ContextMenuItemDivider(),
    ];

    if (isOwnerOrAdmin) {
      // Owner/Admin specific items
      // Clear messages
      menuItems
        ..add(
          ContextMenuItem(
            label: context.i18n.group_clear_messages,
            iconAsset: Assets.svg.iconPopupClear,
            onPressed: () {
              closeMenu();
              ClearGroupMessagesConfirmRoute(conversationId: conversationId).push<void>(context);
            },
          ),
        )
        // Delete group
        ..add(
          const ContextMenuItemDivider(),
        )
        ..add(
          ContextMenuItem(
            label: context.i18n.group_delete_group,
            iconAsset: Assets.svg.iconBlockDelete,
            textColor: context.theme.appColors.attentionRed,
            iconColor: context.theme.appColors.attentionRed,
            onPressed: () {
              closeMenu();
              DeleteGroupConfirmRoute(conversationId: conversationId).push<void>(context);
            },
          ),
        );
    } else {
      // Regular user items
      // Report
      menuItems.add(
        ContextMenuItem(
          label: context.i18n.button_report,
          iconAsset: Assets.svg.iconReport,
          onPressed: () {
            closeMenu();
            final messages = ref
                .read(
                  conversationMessagesProvider(conversationId, ConversationType.groupEncrypted),
                )
                .valueOrNull;
            final lastMessage = messages?.entries.lastOrNull?.value.last;
            if (lastMessage != null) {
              final entity = EncryptedGroupMessageEntity.fromEventMessage(lastMessage);
              ref.read(reportNotifierProvider.notifier).report(
                    ReportReason.content(
                      text: context.i18n.report_content_description,
                      eventReference: entity.toEventReference(),
                    ),
                  );
            }
          },
        ),
      );
    }

    // Leave (for everyone)
    menuItems
      ..add(
        const ContextMenuItemDivider(),
      )
      ..add(
        ContextMenuItem(
          label: context.i18n.group_leave,
          iconAsset: Assets.svg.iconMenuLogout,
          textColor: context.theme.appColors.attentionRed,
          iconColor: context.theme.appColors.attentionRed,
          onPressed: () {
            closeMenu();
            LeaveGroupConfirmRoute().push<void>(context);
          },
        ),
      );

    return menuItems;
  }
}
