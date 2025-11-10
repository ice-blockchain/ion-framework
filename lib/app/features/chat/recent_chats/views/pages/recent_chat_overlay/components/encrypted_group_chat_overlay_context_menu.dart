// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/overlay_menu/components/overlay_menu_item.dart';
import 'package:ion/app/components/overlay_menu/components/overlay_menu_item_separator.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu_container.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/encrypted_direct_message_entity.f.dart';
import 'package:ion/app/features/chat/providers/muted_conversations_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/model/conversation_list_item.f.dart';
import 'package:ion/app/features/chat/recent_chats/providers/toggle_archive_conversation_provider.r.dart';
import 'package:ion/app/features/user/providers/report_notifier.m.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class EncryptedGroupChatOverlayContextMenu extends ConsumerWidget {
  const EncryptedGroupChatOverlayContextMenu({
    required this.conversation,
    super.key,
  });

  final ConversationListItem conversation;

  static final height = 148.0.s;

  static double get iconSize => 20.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMuted = ref
            .watch(mutedConversationIdsProvider)
            .valueOrNull
            ?.contains(conversation.conversationId) ??
        false;

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
                  label: conversation.isArchived
                      ? context.i18n.common_unarchive_single
                      : context.i18n.common_add_to_archive,
                  icon: Assets.svg.iconChatArchive.icon(
                    size: iconSize,
                    color: context.theme.appColors.quaternaryText,
                  ),
                  onPressed: () {
                    ref
                        .read(toggleArchivedConversationsProvider.notifier)
                        .toggleConversations([conversation]);
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
                  onPressed: () {
                    final currentUserPubkey = ref.watch(currentPubkeySelectorProvider);
                    final receiverPubkey = EncryptedDirectMessageData.fromEventMessage(
                      conversation.latestMessage!,
                    ).relatedPubkeys?.firstWhereOrNull((p) => p.value != currentUserPubkey)?.value;

                    if (receiverPubkey == null) {
                      return;
                    }

                    ref
                        .read(mutedConversationsProvider.notifier)
                        .toggleMutedMasterPubkey(receiverPubkey);
                    Navigator.of(context).pop();
                  },
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
