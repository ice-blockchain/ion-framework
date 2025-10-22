// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/chat_medias_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_e2ee_reaction_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/shared_post_message_provider.r.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/model/message_list_item.f.dart';
import 'package:ion/app/features/chat/model/message_type.dart';
import 'package:ion/app/features/chat/providers/message_status_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/money_message_provider.r.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_reaction_dialog/message_reaction_dialog.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/providers/parsed_media_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_media_content.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/generated/assets.gen.dart';

class MessageItemWrapper extends HookConsumerWidget {
  const MessageItemWrapper({
    required this.isMe,
    required this.child,
    required this.messageItem,
    required this.contentPadding,
    this.isLastMessageFromAuthor = true,
    this.margin,
    super.key,
  });

  final bool isMe;
  final Widget child;
  final bool isLastMessageFromAuthor;
  final EdgeInsetsDirectional? margin;
  final ChatMessageInfoItem messageItem;
  final EdgeInsetsGeometry contentPadding;

  /// The maximum width of the message content in the chat
  static double get maxWidth => 282.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageItemKey = useMemoized(GlobalKey.new);

    final entity = useMemoized(
      () => ReplaceablePrivateDirectMessageEntity.fromEventMessage(messageItem.eventMessage),
      [messageItem.eventMessage],
    );

    final deliveryStatus = _getDeliveryStatus(
      ref: ref,
      entity: entity,
      context: context,
      messageItem: messageItem,
    );

    if (deliveryStatus == MessageDeliveryStatus.deleted) {
      return const SizedBox.shrink();
    }

    final showReactDialog = useCallback(
      () async {
        try {
          final emoji = await showDialog<String>(
            context: context,
            barrierColor: Colors.transparent,
            useSafeArea: false,
            builder: (context) => MessageReactionDialog(
              isMe: isMe,
              messageItem: messageItem,
              isSharedPost: messageItem is PostItem,
              messageStatus: deliveryStatus,
              renderObject: messageItemKey.currentContext!.findRenderObject()!,
            ),
          );

          if (emoji != null) {
            final messageEventReference =
                ReplaceablePrivateDirectMessageEntity.fromEventMessage(messageItem.eventMessage)
                    .toEventReference();
            final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
            final isExist = await ref.read(conversationMessageReactionDaoProvider).isReactionExist(
                  messageEventReference: messageEventReference,
                  emoji: emoji,
                  masterPubkey: currentUserMasterPubkey!,
                );

            if (!isExist) {
              final e2eeReactionService = await ref.read(sendE2eeReactionServiceProvider.future);
              await e2eeReactionService.sendReaction(
                content: emoji,
                kind14Rumor: messageItem.eventMessage,
              );
            }
          }
        } catch (e, st) {
          Logger.log('Error showing message reaction dialog:', error: e, stackTrace: st);
        }
      },
      [messageItemKey, isMe, messageItem, deliveryStatus],
    );

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Align(
        alignment: isMe ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
        child: GestureDetector(
          onLongPress: () {
            HapticFeedback.mediumImpact();
            showReactDialog();
          },
          child: RepaintBoundary(
            key: messageItemKey,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: contentPadding,
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? context.theme.appColors.primaryAccent
                        : context.theme.appColors.onPrimaryAccent,
                    borderRadius: BorderRadiusDirectional.only(
                      topStart: Radius.circular(12.0.s),
                      topEnd: Radius.circular(12.0.s),
                      bottomStart:
                          !isLastMessageFromAuthor || isMe ? Radius.circular(12.0.s) : Radius.zero,
                      bottomEnd: isMe && isLastMessageFromAuthor && (messageItem is! PostItem)
                          ? Radius.zero
                          : Radius.circular(12.0.s),
                    ),
                  ),
                  child: child,
                ),
                if (deliveryStatus == MessageDeliveryStatus.failed)
                  Row(
                    children: [
                      SizedBox(width: 6.0.s),
                      Assets.svg.iconMessageFailed.icon(
                        color: context.theme.appColors.attentionRed,
                        size: 16.0.s,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  MessageDeliveryStatus _getDeliveryStatus({
    required WidgetRef ref,
    required BuildContext context,
    required ChatMessageInfoItem messageItem,
    required ReplaceablePrivateDirectMessageEntity entity,
  }) {
    final eventReference = entity.toEventReference();
    final provider = messageItem is PostItem
        ? sharedPostMessageStatusProvider(entity)
        : messageStatusProvider(eventReference);

    return ref.watch(
          provider.select((value) {
            final status = value.valueOrNull;
            if (status != null) {
              ListCachedObjects.updateObject<MessageStatusWithKey>(
                context,
                (key: eventReference.toString(), status: status),
              );
            }
            return status;
          }),
        ) ??
        ListCachedObjects.maybeObjectOf<MessageStatusWithKey>(
          context,
          eventReference.toString(),
        )?.status ??
        MessageDeliveryStatus.created;
  }
}

ChatMessageInfoItem? getRepliedMessageListItem({
  required WidgetRef ref,
  required EventMessage? repliedEventMessage,
}) {
  if (repliedEventMessage == null) {
    return null;
  }

  final repliedEntity = useMemoized(
    () => ReplaceablePrivateDirectMessageEntity.fromEventMessage(repliedEventMessage),
    [repliedEventMessage],
  );

  if (repliedEntity.data.messageType == MessageType.profile) {
    final profilePubkey = EventReference.fromEncoded(repliedEntity.data.content).masterPubkey;

    final userName = ref.watch(
      userPreviewDataProvider(profilePubkey).select(userPreviewNameSelector),
    );

    return ShareProfileItem(
      eventMessage: repliedEventMessage,
      contentDescription: userName.isEmpty ? repliedEntity.data.content : userName,
    );
  } else if (repliedEntity.data.messageType == MessageType.visualMedia) {
    final messageMedias = ref
            .watch(chatMediasProvider(eventReference: repliedEntity.toEventReference()))
            .valueOrNull ??
        [];

    return MediaItem(
      medias: messageMedias,
      eventMessage: repliedEventMessage,
      contentDescription: ref.context.i18n.common_media,
    );
  } else if (repliedEntity.data.messageType == MessageType.sharedPost) {
    final sharedEntity = useMemoized(
      () => ReplaceablePrivateDirectMessageEntity.fromEventMessage(repliedEventMessage),
      [repliedEventMessage],
    );

    final postEntity = sharedEntity.data.quotedEvent != null
        ? ref
            .watch(
              sharedPostMessageProvider(sharedEntity.data.quotedEvent!.eventReference),
            )
            .valueOrNull
        : null;

    final postData = useMemoized(
      () => switch (postEntity) {
        final ModifiablePostEntity post => post.data,
        final PostEntity post => post.data,
        _ => false,
      },
      [postEntity],
    );

    final postDeleted = useMemoized(
      () => switch (postEntity) {
        final ModifiablePostEntity post => post.isDeleted,
        _ => false,
      },
      [postEntity],
    );

    if (postData is! EntityDataWithMediaContent || postDeleted) {
      return PostItem(
        eventMessage: repliedEventMessage,
        contentDescription: ref.context.i18n.story_reply_not_available_receiver,
        medias: [],
      );
    }

    final (:content, :media) = ref.watch(cachedParsedMediaProvider(postData));

    final contentAsPlainText = useMemoized(
      () => Document.fromDelta(content).toPlainText().trim(),
      [content],
    );

    return PostItem(
      medias: media,
      eventMessage: repliedEventMessage,
      contentDescription:
          contentAsPlainText.isNotEmpty ? contentAsPlainText : ref.context.i18n.common_post,
    );
  }

  return switch (repliedEntity.data.messageType) {
    MessageType.profile => null,
    MessageType.sharedPost => null,
    MessageType.visualMedia => null,
    MessageType.requestFunds => MoneyItem(
        eventMessage: repliedEventMessage,
        contentDescription: getRequestFundsTitle(ref, repliedEventMessage) ?? '',
      ),
    MessageType.moneySent => MoneyItem(
        eventMessage: repliedEventMessage,
        contentDescription: getMoneySentTitle(ref, repliedEventMessage) ?? '',
      ),
    MessageType.text => TextItem(
        eventMessage: repliedEventMessage,
        contentDescription: repliedEntity.data.content,
      ),
    MessageType.emoji => EmojiItem(
        eventMessage: repliedEventMessage,
        contentDescription: repliedEntity.data.content,
      ),
    MessageType.audio => AudioItem(
        eventMessage: repliedEventMessage,
        contentDescription: ref.context.i18n.common_voice_message,
      ),
    MessageType.document => DocumentItem(
        eventMessage: repliedEventMessage,
        contentDescription: repliedEntity.data.primaryMedia?.alt ?? '',
      ),
  };
}

String? getMoneySentTitle(WidgetRef ref, EventMessage? eventMessage) {
  if (eventMessage != null) {
    final moneyData = ref.watch(transactionDisplayDataProvider(eventMessage)).value;

    if (moneyData != null) {
      final coinsAmount = '${moneyData.amount} ${moneyData.coin}';

      return ref.watch(isCurrentUserSelectorProvider(eventMessage.masterPubkey))
          ? ref.context.i18n.chat_money_sent_preview_title(coinsAmount)
          : ref.context.i18n.chat_money_received_preview_title(coinsAmount);
    }
  }
  return null;
}

String? getRequestFundsTitle(WidgetRef ref, EventMessage? eventMessage) {
  if (eventMessage != null) {
    final moneyData = ref.watch(fundsRequestDisplayDataProvider(eventMessage)).value;

    if (moneyData != null) {
      final coinsAmount = '${moneyData.amount} ${moneyData.coin}';

      return ref.watch(isCurrentUserSelectorProvider(eventMessage.masterPubkey))
          ? ref.context.i18n.chat_money_my_request_preview_title(coinsAmount)
          : ref.context.i18n.chat_money_request_preview_title(coinsAmount);
    }
  }

  return null;
}
