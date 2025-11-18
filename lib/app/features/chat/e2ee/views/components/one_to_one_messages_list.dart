// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_e2ee_message_status_provider.r.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/model/message_type.dart';
import 'package:ion/app/features/chat/providers/conversation_messages_provider.r.dart';
import 'package:ion/app/features/chat/views/components/message_items/components.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_types/document_message/document_message.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_types/post_message/post_message.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_types/visual_media_message/visual_media_message.dart';
import 'package:ion/app/features/chat/views/components/scroll_to_bottom_button.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/utils/date.dart';
import 'package:ion/app/utils/future.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class OneToOneMessageList extends HookConsumerWidget {
  const OneToOneMessageList(
    this.messages, {
    required this.conversationId,
    super.key,
  });

  final List<EventMessage> messages;
  final String conversationId;

  static double _getEstimatedHeight(MessageType messageType) {
    switch (messageType) {
      case MessageType.text:
        return 60.0.s;
      case MessageType.profile:
        return 80.0.s;
      case MessageType.visualMedia:
        return 200.0.s;
      case MessageType.sharedPost:
        return 150.0.s;
      case MessageType.requestFunds:
      case MessageType.moneySent:
        return 100.0.s;
      case MessageType.emoji:
        return 50.0.s;
      case MessageType.audio:
        return 80.0.s;
      case MessageType.document:
        return 90.0.s;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final listController = useMemoized(ListController.new);

    useEffect(
      () {
        _markAsRead(ref, messages);
        return null;
      },
      [messages],
    );

    final animateToItem = useCallback(
      (int index) {
        listController.animateToItem(
          index: index,
          scrollController: scrollController,
          alignment: 0,
          duration: (d) => 300.milliseconds,
          curve: (c) => Curves.easeInOut,
        );
      },
      [scrollController, listController, messages.length],
    );

    final onTapReply = useCallback(
      (ReplaceablePrivateDirectMessageEntity entity) async {
        final replyMessage = entity.data.relatedEvents?.singleOrNull;

        if (replyMessage != null) {
          final replySharedId = replyMessage.eventReference.dTag;

          var replyMessageIndex = messages.indexWhere(
            (element) => element.sharedId == replySharedId,
          );

          if (replyMessageIndex == -1) {
            replyMessageIndex = await ref
                    .read(conversationMessagesProvider(conversationId).notifier)
                    .ensureMessageLoaded(replySharedId) ??
                -1;
          }

          if (replyMessageIndex != -1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              animateToItem(replyMessageIndex);
            });
          }
        }
      },
      [
        messages,
        conversationId,
        scrollController,
        listController,
      ], // Optimized dependencies
    );

    //trigger load more when scroll to bottom
    useEffect(
      () {
        void listener() {
          if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 20) {
            ref.read(conversationMessagesProvider(conversationId).notifier).loadMore();
          }
        }

        scrollController.addListener(listener);
        return () => scrollController.removeListener(listener);
      },
      [scrollController],
    );

    print('[CUSTOM LOG] messages.length: ${messages.length}');

    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (notification) {
        if (notification.scrollDelta != null && notification.scrollDelta! > 0) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
        return false;
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: context.theme.appColors.primaryBackground,
            child: SuperListView.builder(
              reverse: true,
              cacheExtent: 100,
              itemCount: messages.length,
              controller: scrollController,
              listController: listController,
              key: const Key('one_to_one_messages_list'),
              padding: EdgeInsetsDirectional.only(bottom: 12.s),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              findChildIndexCallback: (key) {
                final valueKey = key as ValueKey<String>;
                return messages.indexWhere((e) => e.id == valueKey.value);
              },
              // Add item extent estimation for better scroll performance
              extentEstimation: (index, dimensions) {
                if (index == null || index >= messages.length) return 60.0.s; // Default height
                final message = messages[index];
                final entity = ReplaceablePrivateDirectMessageEntity.fromEventMessage(
                  message,
                );

                // Base height estimate for the message type
                var estimatedHeight = _getEstimatedHeight(entity.data.messageType);

                // Add date header height if this message shows a date
                final currentMessageDate = message.publishedAt.toDateTime;
                final previousMessageDate = (index < messages.length - 1)
                    ? messages[index + 1].publishedAt.toDateTime
                    : null;

                final hasDateHeader = previousMessageDate == null ||
                    !isSameDay(previousMessageDate, currentMessageDate);
                if (hasDateHeader) {
                  estimatedHeight += 50.0.s; // Date header height estimate
                }

                // Add margin spacing
                final isLastMessageInConversation = index == 0;
                final hasNextMessageFromAnotherUser =
                    index > 0 && messages[index - 1].masterPubkey != message.masterPubkey;

                if (!isLastMessageInConversation) {
                  if (hasNextMessageFromAnotherUser) {
                    estimatedHeight += 16.0;
                  } else {
                    estimatedHeight += 8.0;
                  }
                }

                return estimatedHeight;
              },
              itemBuilder: (context, index) {
                final message = messages[index];

                final entity = ReplaceablePrivateDirectMessageEntity.fromEventMessage(
                  message,
                );

                final currentMessageDate = message.publishedAt.toDateTime;
                final nextMessageDate =
                    index < messages.length - 1 ? messages[index + 1].publishedAt.toDateTime : null;
                final hasDateHeader =
                    nextMessageDate == null || (!isSameDay(currentMessageDate, nextMessageDate));
                final isLastMessageInConversation = index == 0;

                final hasNextMessageFromAnotherUser =
                    index > 0 && messages[index - 1].masterPubkey != message.masterPubkey;

                final isPreviousMessageFromAnotherDay = index > 0 &&
                    !isSameDay(
                      messages[index - 1].publishedAt.toDateTime,
                      message.publishedAt.toDateTime,
                    );

                final margin = EdgeInsetsDirectional.only(
                  bottom: isLastMessageInConversation || isPreviousMessageFromAnotherDay
                      ? 0
                      : hasNextMessageFromAnotherUser
                          ? 16.0.s
                          : 8.0.s,
                );

                return Column(
                  key: ValueKey(message.id),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasDateHeader) ChatDateHeaderText(date: currentMessageDate),
                    switch (entity.data.messageType) {
                      MessageType.text => TextMessage(
                          margin: margin,
                          eventMessage: message,
                          onTapReply: () => onTapReply(entity),
                        ),
                      MessageType.profile => ProfileShareMessage(
                          margin: margin,
                          eventMessage: message,
                          onTapReply: () => onTapReply(entity),
                        ),
                      MessageType.visualMedia => VisualMediaMessage(
                          margin: margin,
                          eventMessage: message,
                          onTapReply: () => onTapReply(entity),
                        ),
                      MessageType.sharedPost => PostMessage(
                          margin: margin,
                          eventMessage: message,
                          onTapReply: () => onTapReply(entity),
                        ),
                      MessageType.requestFunds || MessageType.moneySent => MoneyMessage(
                          margin: margin,
                          eventMessage: message,
                          onTapReply: () => onTapReply(entity),
                        ),
                      MessageType.emoji => EmojiMessage(
                          margin: margin,
                          eventMessage: message,
                          onTapReply: () => onTapReply(entity),
                        ),
                      MessageType.audio => AudioMessage(
                          margin: margin,
                          eventMessage: message,
                          onTapReply: () => onTapReply(entity),
                        ),
                      MessageType.document => DocumentMessage(
                          margin: margin,
                          eventMessage: message,
                          onTapReply: () => onTapReply(entity),
                        ),
                    },
                  ],
                );
              },
            ),
          ),
          ScrollToBottomButton(
            scrollController: scrollController,
            onTap: () => animateToItem(0),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsRead(
    WidgetRef ref,
    List<EventMessage> allMessages,
  ) async {
    final currentUserMasterPubkey = ref.read(currentPubkeySelectorProvider);

    final latestMessageFromReceiver =
        allMessages.where((m) => m.masterPubkey != currentUserMasterPubkey).firstOrNull;

    if (latestMessageFromReceiver == null || currentUserMasterPubkey == null) {
      return;
    }

    final service = await ref.read(sendE2eeMessageStatusServiceProvider.future);

    await service.sendMessageStatus(
      messageEventMessage: latestMessageFromReceiver,
      status: MessageDeliveryStatus.read,
    );
  }
}
