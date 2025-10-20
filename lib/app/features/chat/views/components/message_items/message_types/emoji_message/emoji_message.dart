// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/hooks/use_has_reaction.dart';
import 'package:ion/app/features/chat/model/message_list_item.f.dart';
import 'package:ion/app/features/chat/recent_chats/providers/replied_message_list_item_provider.r.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_item_wrapper/message_item_wrapper.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_metadata/message_metadata.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_reactions/message_reactions.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_types/reply_message/reply_message.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';

class EmojiMessage extends HookConsumerWidget {
  const EmojiMessage({
    required this.eventMessage,
    this.margin,
    this.onTapReply,
    super.key,
  });

  final EventMessage eventMessage;
  final VoidCallback? onTapReply;
  final EdgeInsetsDirectional? margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entity = useMemoized(
      () => ReplaceablePrivateDirectMessageEntity.fromEventMessage(eventMessage),
      [eventMessage],
    );

    final isMe = ref.watch(isCurrentUserSelectorProvider(eventMessage.masterPubkey));

    final hasReaction = useHasReaction(entity.toEventReference(), ref);

    final messageItem = useMemoized(
      () => TextItem(
        eventMessage: eventMessage,
        contentDescription: eventMessage.content,
      ),
      [eventMessage],
    );

    final repliedEventMessage = ref.watch(
          repliedMessageListItemProvider(messageItem).select((value) {
            final repliedEvent = value.valueOrNull;

            if (repliedEvent != null) {
              ListCachedObjects.updateObject<EventMessage>(context, repliedEvent);
            }
            return repliedEvent;
          }),
        ) ??
        ListCachedObjects.maybeObjectOf<EventMessage>(
          context,
          entity.data.parentEvent?.eventReference.dTag,
        );

    final repliedMessageItem = getRepliedMessageListItem(
      ref: ref,
      repliedEventMessage: repliedEventMessage,
    );

    return MessageItemWrapper(
      isMe: isMe,
      margin: margin,
      messageItem: messageItem,
      contentPadding: EdgeInsets.symmetric(horizontal: 12.0.s, vertical: 6.0.s),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (repliedMessageItem != null)
              ReplyMessage(messageItem, repliedMessageItem, onTapReply),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entity.data.content,
                  style: context.theme.appTextThemes.headline1.platformEmojiAware(),
                ),
                if (!hasReaction) MessageMetadata(eventMessage: eventMessage),
              ],
            ),
            if (hasReaction)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: MessageReactions(eventMessage: eventMessage, isMe: isMe),
                  ),
                  MessageMetadata(eventMessage: eventMessage, startPadding: 0.0.s),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

extension GoogleFontsPlatformExtension on TextStyle {
  TextStyle platformEmojiAware() {
    return Platform.isAndroid
        ? GoogleFonts.getFont(
            'Noto Color Emoji',
            textStyle: this,
          )
        : this;
  }
}
