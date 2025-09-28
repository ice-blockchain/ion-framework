// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/avatar/avatar.dart';
import 'package:ion/app/components/avatar/story_colored_profile_avatar.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/model/message_type.dart';
import 'package:ion/app/features/chat/providers/muted_conversations_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/model/conversation_list_item.f.dart';
import 'package:ion/app/features/chat/recent_chats/providers/conversations_edit_mode_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/selected_conversations_ids_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/views/pages/recent_chat_overlay/recent_chat_overlay.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_item_wrapper/message_item_wrapper.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_metadata/message_metadata.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_types/emoji_message/emoji_message.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/user_block/providers/block_list_notifier.r.dart';
import 'package:ion/app/utils/date.dart';
import 'package:ion/generated/assets.gen.dart';

class RecentChatTile extends HookConsumerWidget {
  const RecentChatTile({
    required this.name,
    required this.onTap,
    required this.messageType,
    required this.conversation,
    required this.defaultAvatar,
    required this.lastMessageAt,
    required this.eventReference,
    required this.lastMessageContent,
    required this.unreadMessagesCount,
    this.avatarUrl,
    this.avatarWidget,
    this.isVerified = false,
    super.key,
  });

  final String name;
  final String? avatarUrl;
  final Widget? defaultAvatar;
  final EventReference? eventReference;
  final DateTime lastMessageAt;
  final int unreadMessagesCount;
  final String lastMessageContent;
  final VoidCallback? onTap;
  final Widget? avatarWidget;
  final MessageType messageType;
  final ConversationListItem conversation;
  final bool isVerified;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditMode = ref.watch(conversationsEditModeProvider);
    final selectedConversations = ref.watch(selectedConversationsProvider);

    final isMuted = ref
            .watch(mutedConversationIdsProvider)
            .valueOrNull
            ?.contains(conversation.conversationId) ??
        false;

    final messageItemKey = useMemoized(GlobalKey.new);

    final isMe = conversation.latestMessage != null &&
        ref.watch(isCurrentUserSelectorProvider(conversation.latestMessage!.masterPubkey));

    final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);

    if (currentUserMasterPubkey == null) {
      return const SizedBox.shrink();
    }

    final otherUserPubkey = conversation.latestMessage != null
        ? conversation.receiverMasterPubkey(currentUserMasterPubkey)
        : null;

    final isBlockedBy = ref
            .watch(
              isBlockedByNotifierProvider(
                conversation.latestMessage!.participantsMasterPubkeys.singleWhere(
                  (pubkey) => pubkey != currentUserMasterPubkey,
                ),
              ),
            )
            .valueOrNull ??
        false;

    final showRecentChatOverlay = useCallback(
      () {
        showDialog<void>(
          context: context,
          barrierColor: Colors.transparent,
          useSafeArea: false,
          builder: (context) => RecentChatOverlay(
            conversation: conversation,
            renderObject: messageItemKey.currentContext!.findRenderObject()!,
          ),
        );
      },
      [messageItemKey],
    );

    return GestureDetector(
      onTap: () {
        print('delete');
        //check is wrap_ids_index index exists in event_message_table
        // final db = ref.watch(chatDatabaseProvider);
        // final indexExists = db.wrapIdsIndex;
        // print('$indexExists');
        // return;
        if (isEditMode) {
          ref.read(selectedConversationsProvider.notifier).toggle(conversation);
        } else {
          onTap?.call();
        }
      },
      onLongPress: showRecentChatOverlay,
      behavior: HitTestBehavior.opaque,
      child: RepaintBoundary(
        key: messageItemKey,
        child: Container(
          decoration: BoxDecoration(
            color: context.theme.appColors.secondaryBackground,
          ),
          padding: EdgeInsets.symmetric(vertical: 8.0.s),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isEditMode ? 40.0.s : 0,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(end: 10.0.s),
                  child: selectedConversations.contains(conversation)
                      ? Assets.svg.iconBlockCheckboxOn.icon(size: 24.0.s)
                      : Assets.svg.iconBlockCheckboxOff.icon(size: 24.0.s),
                ),
              ),
              Flexible(
                child: Row(
                  children: [
                    if (isBlockedBy)
                      Avatar(size: 48.0.s)
                    else if (otherUserPubkey != null)
                      StoryColoredProfileAvatar(
                        pubkey: otherUserPubkey,
                        size: 48.0.s,
                        imageUrl: avatarUrl,
                        imageWidget: avatarWidget,
                        defaultAvatar: defaultAvatar,
                        useRandomGradient: true,
                      )
                    else
                      Avatar(
                        imageUrl: avatarUrl,
                        imageWidget: avatarWidget,
                        defaultAvatar: defaultAvatar,
                        size: 48.0.s,
                      ),
                    SizedBox(width: 12.0.s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Row(
                                  children: <Widget>[
                                    Flexible(
                                      child: Text(
                                        name,
                                        style: context.theme.appTextThemes.subtitle3.copyWith(
                                          color: context.theme.appColors.primaryText,
                                        ),
                                        maxLines: 1,
                                      ),
                                    ),
                                    if (isVerified)
                                      Padding(
                                        padding: EdgeInsetsDirectional.only(start: 4.0.s),
                                        child: Assets.svg.iconBadgeVerify.icon(size: 16.0.s),
                                      ),
                                    if (isMuted)
                                      Padding(
                                        padding: EdgeInsetsDirectional.only(start: 4.0.s),
                                        child: Assets.svg.iconChannelfillMute.icon(size: 16.0.s),
                                      ),
                                  ],
                                ),
                              ),
                              ChatTimestamp(lastMessageAt),
                            ],
                          ),
                          SizedBox(height: 2.0.s),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: ChatPreview(
                                  messageType: messageType,
                                  eventReference: eventReference,
                                  lastMessageContent: lastMessageContent,
                                  lastMessage: conversation.latestMessage,
                                ),
                              ),
                              if (isMe)
                                MessageMetaData(
                                  displayTime: false,
                                  displayEdited: false,
                                  deliveryStatusIconSize: 16.0.s,
                                  eventMessage: conversation.latestMessage!,
                                ),
                              if (unreadMessagesCount > 0)
                                UnreadCountBadge(
                                  isMuted: isMuted,
                                  unreadCount: unreadMessagesCount,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SenderSummary extends ConsumerWidget {
  const SenderSummary({
    required this.pubkey,
    this.textColor,
    this.isReply = false,
    this.isEdit = false,
    super.key,
  });

  final bool isReply;
  final bool isEdit;
  final String pubkey;

  final Color? textColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMetadata = ref.watch(userMetadataFromDbProvider(pubkey));

    if (userMetadata == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (isReply)
          Padding(
            padding: EdgeInsetsDirectional.only(end: 4.0.s),
            child: Assets.svg.iconChatReply.icon(
              size: 16.0.s,
              color: context.theme.appColors.quaternaryText,
            ),
          ),
        if (isEdit)
          Padding(
            padding: EdgeInsetsDirectional.only(end: 4.0.s),
            child: Assets.svg.iconEditLink.icon(
              size: 16.0.s,
              color: context.theme.appColors.quaternaryText,
            ),
          ),
        Text(
          isEdit ? context.i18n.button_edit : userMetadata.data.name,
          style: context.theme.appTextThemes.subtitle3.copyWith(
            color: textColor ?? context.theme.appColors.primaryText,
          ),
        ),
      ],
    );
  }
}

class ChatTimestamp extends StatelessWidget {
  const ChatTimestamp(this.time, {super.key});

  final DateTime time;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatMessageTimestamp(time),
      style: context.theme.appTextThemes.caption3.copyWith(
        color: context.theme.appColors.onTertiaryBackground,
      ),
    );
  }
}

class ChatPreview extends HookConsumerWidget {
  const ChatPreview({
    required this.messageType,
    required this.lastMessageContent,
    this.lastMessage,
    this.eventReference,
    this.textColor,
    this.maxLines = 2,
    super.key,
  });

  final int maxLines;
  final String lastMessageContent;
  final EventMessage? lastMessage;
  final Color? textColor;
  final EventReference? eventReference;
  final MessageType messageType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = switch (messageType) {
      MessageType.text => lastMessageContent,
      MessageType.emoji => lastMessageContent,
      MessageType.sharedPost =>
        lastMessageContent.isNotEmpty ? lastMessageContent : context.i18n.post_page_title,
      MessageType.audio => context.i18n.common_voice_message,
      MessageType.visualMedia => context.i18n.common_media,
      MessageType.document => lastMessageContent,
      MessageType.requestFunds => getRequestFundsTitle(ref, lastMessage) ?? lastMessageContent,
      MessageType.moneySent => getMoneySentTitle(ref, lastMessage) ?? lastMessageContent,
      MessageType.profile => ref
              .watch(
                userMetadataProvider(
                  EventReference.fromEncoded(lastMessageContent).masterPubkey,
                ),
              )
              .valueOrNull
              ?.data
              .displayName ??
          '',
    };

    final storyReactionContent =
        ref.watch(conversationMessageReactionDaoProvider).storyReactionContent(eventReference);

    return Row(
      children: [
        RecentChatMessageIcon(messageType: messageType, color: textColor),
        Flexible(
          child: StreamBuilder(
            stream: storyReactionContent,
            builder: (context, snapshot) {
              return Text(
                snapshot.hasData ? snapshot.data ?? content : content,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: messageType == MessageType.emoji
                    ? context.theme.appTextThemes.body2
                        .copyWith(
                          color: textColor ?? context.theme.appColors.onTertiaryBackground,
                        )
                        .platformEmojiAware()
                    : context.theme.appTextThemes.body2.copyWith(
                        color: textColor ?? context.theme.appColors.onTertiaryBackground,
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class RecentChatMessageIcon extends StatelessWidget {
  const RecentChatMessageIcon({required this.messageType, this.color, super.key});

  final MessageType messageType;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final messageIconPath = _getMessageIcon();

    if (messageIconPath != null) {
      return Padding(
        padding: EdgeInsetsDirectional.only(end: 2.0.s),
        child: messageIconPath.icon(
          size: 16.0.s,
          color: color ?? context.theme.appColors.onTertiaryBackground,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  String? _getMessageIcon() => switch (messageType) {
        MessageType.text => null,
        MessageType.emoji => null,
        MessageType.sharedPost => Assets.svg.iconProfileFeed,
        MessageType.audio => Assets.svg.iconChatVoicemessage,
        MessageType.profile => Assets.svg.iconProfileUsertab,
        MessageType.document => Assets.svg.iconChatFile,
        MessageType.visualMedia => Assets.svg.iconProfileCamera,
        MessageType.requestFunds || MessageType.moneySent => Assets.svg.iconProfileTips,
      };
}

class UnreadCountBadge extends StatelessWidget {
  const UnreadCountBadge({required this.unreadCount, required this.isMuted, super.key});

  final int unreadCount;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    if (unreadCount == 0) {
      return SizedBox(width: 24.0.s);
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0.s),
        color: isMuted ? context.theme.appColors.sheetLine : context.theme.appColors.primaryAccent,
      ),
      alignment: Alignment.center,
      constraints: BoxConstraints(
        minWidth: 16.0.s,
        minHeight: 16.0.s,
        maxHeight: 16.0.s,
      ),
      padding: EdgeInsetsDirectional.fromSTEB(5.0.s, 0, 5.0.s, 1.0.s),
      margin: EdgeInsetsDirectional.only(start: 16.0.s),
      child: Text(
        unreadCount.toString(),
        textAlign: TextAlign.center,
        style: context.theme.appTextThemes.caption3.copyWith(
          height: 1,
          color: context.theme.appColors.onPrimaryAccent,
          fontFeatures: [
            const FontFeature.enable('liga'),
            const FontFeature.disable('clig'),
          ],
        ),
      ),
    );
  }
}
