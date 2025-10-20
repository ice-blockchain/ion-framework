// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/overlay_menu/components/overlay_menu_item.dart';
import 'package:ion/app/components/overlay_menu/components/overlay_menu_item_separator.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu_container.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/e2ee_delete_event_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_chat_message/send_e2ee_chat_message_service.r.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/model/message_list_item.f.dart';
import 'package:ion/app/features/chat/model/message_type.dart';
import 'package:ion/app/features/chat/providers/share_feed_item_to_chat_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/selected_edit_message_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/selected_reply_message_provider.r.dart';
import 'package:ion/app/features/core/model/feature_flags.dart';
import 'package:ion/app/features/core/providers/feature_flags_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/story_reply_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/clipboard/clipboard.dart';
import 'package:ion/generated/assets.gen.dart';

class MessageReactionContextMenu extends HookConsumerWidget {
  const MessageReactionContextMenu({
    required this.isMe,
    required this.messageItem,
    required this.messageStatus,
    this.isSharedPost = false,
    this.isSharedStory = false,
    super.key,
  });

  final bool isMe;
  final bool isSharedPost;
  final bool isSharedStory;
  final ChatMessageInfoItem messageItem;
  final MessageDeliveryStatus messageStatus;

  static double get iconSize => 20.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entityData = useMemoized(
      () => ReplaceablePrivateDirectMessageData.fromEventMessage(messageItem.eventMessage),
      [messageItem.eventMessage],
    );

    final canEdit = entityData.editingEndedAt.value.toDateTime.isAfter(DateTime.now());
    final hideChatBookmark =
        ref.watch(featureFlagsProvider.notifier).get(ChatFeatureFlag.hideChatBookmark);

    final canCopy = entityData.messageType == MessageType.text ||
        entityData.messageType == MessageType.emoji ||
        entityData.messageType == MessageType.sharedPost && entityData.content.isNotEmpty;

    return Padding(
      padding: EdgeInsetsDirectional.only(top: 6.0.s),
      child: OverlayMenuContainer(
        child: Column(
          children: [
            if (messageStatus == MessageDeliveryStatus.failed)
              OverlayMenuItem(
                label: context.i18n.button_retry,
                icon: Assets.svg.iconMessageRetry.icon(
                  size: iconSize,
                  color: context.theme.appColors.quaternaryText,
                ),
                onPressed: () async {
                  if (isSharedStory) {
                    unawaited(
                      ref.read(storyReplyProvider.notifier).resendReply(messageItem.eventMessage),
                    );
                  } else if (isSharedPost) {
                    unawaited(
                      ref
                          .read(shareFeedItemToChatProvider.notifier)
                          .resendPost(messageItem.eventMessage),
                    );
                  } else {
                    unawaited(
                      ref.read(sendE2eeChatMessageServiceProvider).resendMessage(
                            eventMessage: messageItem.eventMessage,
                          ),
                    );
                  }

                  if (context.mounted) {
                    context.pop();
                  }
                },
                minWidth: 140.0.s,
                verticalPadding: 12.0.s,
              )
            else ...[
              OverlayMenuItem(
                label: context.i18n.button_reply,
                icon: Assets.svg.iconChatReply.icon(
                  size: iconSize,
                  color: context.theme.appColors.quaternaryText,
                ),
                onPressed: () {
                  ref.read(selectedReplyMessageProvider.notifier).selectedReplyMessage =
                      messageItem;
                  context.pop();
                },
                minWidth: 140.0.s,
                verticalPadding: 12.0.s,
              ),
              if (isMe &&
                  canEdit &&
                  (((messageItem is TextItem) && !(messageItem as TextItem).isStoryReply) ||
                      messageItem is EmojiItem)) ...[
                const OverlayMenuItemSeparator(),
                OverlayMenuItem(
                  label: context.i18n.button_edit,
                  verticalPadding: 12.0.s,
                  icon: Assets.svg.iconEditLink
                      .icon(size: iconSize, color: context.theme.appColors.quaternaryText),
                  onPressed: () {
                    ref.read(selectedReplyMessageProvider.notifier).clear();
                    ref.read(selectedEditMessageProvider.notifier).selectedEditMessage =
                        messageItem;
                    context.pop();
                  },
                ),
              ],
              if (canCopy) ...[
                const OverlayMenuItemSeparator(),
                OverlayMenuItem(
                  label: context.i18n.button_copy,
                  verticalPadding: 12.0.s,
                  icon: Assets.svg.iconBlockCopyBlue
                      .icon(size: iconSize, color: context.theme.appColors.quaternaryText),
                  onPressed: () {
                    copyToClipboard(messageItem.eventMessage.content);
                    Navigator.of(context).pop();
                  },
                ),
              ],
              if (!hideChatBookmark) ...[
                const OverlayMenuItemSeparator(),
                OverlayMenuItem(
                  label: context.i18n.button_bookmark,
                  verticalPadding: 12.0.s,
                  icon: Assets.svg.iconBookmarks
                      .icon(size: iconSize, color: context.theme.appColors.quaternaryText),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ],
            const OverlayMenuItemSeparator(),
            OverlayMenuItem(
              label: context.i18n.button_delete,
              labelColor: context.theme.appColors.attentionRed,
              verticalPadding: 12.0.s,
              icon: Assets.svg.iconBlockDelete
                  .icon(size: iconSize, color: context.theme.appColors.attentionRed),
              onPressed: () async {
                final forEveryone = await DeleteMessageRoute(
                  isMe: isMe,
                ).push<bool>(context);

                if (forEveryone != null && context.mounted) {
                  final messageEventsList = [messageItem.eventMessage];

                  ref.read(
                    e2eeDeleteMessageProvider(
                      forEveryone: forEveryone,
                      messageEvents: messageEventsList,
                    ),
                  );
                  context.pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
