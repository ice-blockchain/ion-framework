// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/overlay_menu/components/overlay_menu_item.dart';
import 'package:ion/app/components/overlay_menu/components/overlay_menu_item_separator.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu_container.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/recent_chats/model/conversation_list_item.f.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/recent_chat_tile/recent_chat_actions.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/block_user_modal/block_user_modal.dart';
import 'package:ion/app/features/user/providers/report_notifier.m.dart';
import 'package:ion/app/features/user_block/optimistic_ui/block_user_provider.r.dart';
import 'package:ion/app/features/user_block/providers/block_list_notifier.r.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';

class RecentChatOverlayContextMenu extends ConsumerWidget {
  const RecentChatOverlayContextMenu({
    required this.conversation,
    super.key,
  });

  final ConversationListItem conversation;

  static final height = 193.0.s;

  static double get iconSize => 20.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
    final receiverMasterPubkey = conversation.receiverMasterPubkey(currentUserMasterPubkey);

    final isBlocked = receiverMasterPubkey == null
        ? false
        : ref.watch(isBlockedNotifierProvider(receiverMasterPubkey)).valueOrNull;

    final actions = buildRecentChatActions(
      context: context,
      ref: ref,
      conversation: conversation,
    );
    final primaryActions =
        actions.where((action) => action.kind != RecentChatActionKind.delete).toList();
    final deleteAction = actions.firstWhere((action) => action.kind == RecentChatActionKind.delete);

    ref.displayErrors(reportNotifierProvider);

    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsetsDirectional.only(top: 6.0.s),
        child: OverlayMenuContainer(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0.s),
            child: Column(
              children: [
                ...[
                  ...primaryActions.map(
                    (action) => _RecentChatOverlayActionItem(action: action),
                  ),
                  if (isBlocked != null && currentUserMasterPubkey != null)
                    OverlayMenuItem(
                      label: isBlocked ? context.i18n.button_unblock : context.i18n.button_block,
                      verticalPadding: 12.0.s,
                      icon: Assets.svg.iconPhofileBlockuser.icon(
                        size: iconSize,
                        color: context.theme.appColors.quaternaryText,
                      ),
                      onPressed: () {
                        context.pop();

                        if (receiverMasterPubkey == null) return;

                        if (!isBlocked) {
                          showSimpleBottomSheet<void>(
                            context: context,
                            child: BlockUserModal(pubkey: receiverMasterPubkey),
                          );
                        } else {
                          ref
                              .read(toggleBlockNotifierProvider.notifier)
                              .toggle(receiverMasterPubkey);
                        }
                      },
                    ),
                  _RecentChatOverlayActionItem(action: deleteAction),
                ].separated(const OverlayMenuItemSeparator()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentChatOverlayActionItem extends StatelessWidget {
  const _RecentChatOverlayActionItem({required this.action});

  final RecentChatActionItem action;

  @override
  Widget build(BuildContext context) {
    final iconColor = action.isDestructive
        ? context.theme.appColors.attentionRed
        : context.theme.appColors.quaternaryText;

    return OverlayMenuItem(
      label: action.label,
      labelColor: action.isDestructive ? context.theme.appColors.attentionRed : null,
      verticalPadding: 12.0.s,
      minWidth: 128.0.s,
      icon: action.icon.icon(size: RecentChatOverlayContextMenu.iconSize, color: iconColor),
      onPressed: () async {
        final shouldClose = await action.onSelected();
        if (shouldClose && context.mounted) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}
