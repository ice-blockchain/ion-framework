// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/overlay_menu/components/overlay_menu_item.dart';
import 'package:ion/app/components/overlay_menu/components/overlay_menu_item_separator.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu_container.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/providers/conversations_provider.r.dart';
import 'package:ion/app/features/chat/providers/muted_conversations_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/model/conversation_list_item.f.dart';
import 'package:ion/app/features/chat/recent_chats/providers/toggle_archive_conversation_provider.r.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/block_user_modal/block_user_modal.dart';
import 'package:ion/app/features/user/providers/report_notifier.m.dart';
import 'package:ion/app/features/user_block/optimistic_ui/block_user_provider.r.dart';
import 'package:ion/app/features/user_block/providers/block_list_notifier.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
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

    final isMuted =
        ref.watch(mutedConversationsProvider).valueOrNull?.contains(conversation.conversationId) ??
            false;

    final isBlocked = receiverMasterPubkey == null
        ? false
        : ref.watch(isBlockedNotifierProvider(receiverMasterPubkey)).valueOrNull;

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
                OverlayMenuItem(
                  label: ref.watch(archivedConversationsProvider).value?.contains(conversation) ??
                          false
                      ? context.i18n.common_unarchive_single
                      : context.i18n.common_add_to_archive,
                  icon: Assets.svg.iconChatArchive.icon(
                    size: iconSize,
                    color: context.theme.appColors.quaternaryText,
                  ),
                  onPressed: () {
                    ref
                        .read(toggleArchivedConversationsProvider.notifier)
                        .toggleConversations([conversation.conversationId]);
                    Navigator.of(context).pop();
                  },
                  minWidth: 128.0.s,
                  verticalPadding: 12.0.s,
                ),
                const OverlayMenuItemSeparator(),
                OverlayMenuItem(
                  label: isMuted ? context.i18n.button_unmute : context.i18n.button_mute,
                  verticalPadding: 12.0.s,
                  icon: isMuted
                      ? Assets.svg.iconChannelUnmute
                          .icon(size: iconSize, color: context.theme.appColors.quaternaryText)
                      : Assets.svg.iconChannelMute
                          .icon(size: iconSize, color: context.theme.appColors.quaternaryText),
                  onPressed: () async {
                    final receiverMasterPubkey =
                        conversation.receiverMasterPubkey(currentUserMasterPubkey);

                    if (receiverMasterPubkey == null) return;

                    final muteConversationService =
                        await ref.read(muteConversationServiceProvider.future);

                    unawaited(
                      muteConversationService.toggleMutedConversation(receiverMasterPubkey),
                    );

                    if (context.mounted) {
                      context.pop();
                    }
                  },
                ),
                if (isBlocked != null && currentUserMasterPubkey != null)
                  Column(
                    children: [
                      const OverlayMenuItemSeparator(),
                      OverlayMenuItem(
                        label: isBlocked ? context.i18n.button_unblock : context.i18n.button_block,
                        verticalPadding: 12.0.s,
                        icon: Assets.svg.iconPhofileBlockuser
                            .icon(size: iconSize, color: context.theme.appColors.quaternaryText),
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
                    ],
                  ),
                const OverlayMenuItemSeparator(),
                OverlayMenuItem(
                  label: context.i18n.button_delete,
                  labelColor: context.theme.appColors.attentionRed,
                  verticalPadding: 12.0.s,
                  icon: Assets.svg.iconBlockDelete
                      .icon(size: iconSize, color: context.theme.appColors.attentionRed),
                  onPressed: () async {
                    final deleted = await DeleteConversationRoute(
                          conversationIds: [conversation.conversationId],
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
      ),
    );
  }
}
