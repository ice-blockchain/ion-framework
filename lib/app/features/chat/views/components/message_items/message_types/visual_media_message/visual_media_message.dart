// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/chat_medias_provider.r.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/model/message_list_item.f.dart';
import 'package:ion/app/features/chat/recent_chats/providers/replied_message_list_item_provider.r.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_item_wrapper/message_item_wrapper.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_types/reply_message/reply_message.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_types/visual_media_message/visual_media_custom_grid.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_types/visual_media_message/visual_media_metadata.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';

class VisualMediaMessage extends HookConsumerWidget {
  const VisualMediaMessage({
    required this.eventMessage,
    this.margin,
    this.onTapReply,
    super.key,
  });

  final VoidCallback? onTapReply;
  final EventMessage eventMessage;
  final EdgeInsetsDirectional? margin;

  static double get padding => 6.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entity = useMemoized(
      () => ReplaceablePrivateDirectMessageEntity.fromEventMessage(eventMessage),
      [eventMessage],
    );

    final eventReference = entity.toEventReference();

    final isMe = ref.watch(isCurrentUserSelectorProvider(eventMessage.masterPubkey));

    final messageMedias = ref.watch(
          chatMediasProvider(eventReference: eventReference).select((value) {
            final medias = value.valueOrNull;

            if (medias != null) {
              ListCachedObjects.updateObjects<MessageMediaTableData>(
                context,
                medias,
                identifierSelectorOverride: (media) => media.id,
              );
            }
            return medias;
          }),
        ) ??
        ListCachedObjects.maybeObjectsOf<MessageMediaTableData>(
          context,
          eventReference,
        );

    final messageItem = useMemoized(
      () => MediaItem(
        medias: messageMedias,
        eventMessage: eventMessage,
        contentDescription: context.i18n.common_media,
      ),
      [messageMedias, eventMessage, context.i18n.common_media],
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
      contentPadding: EdgeInsets.all(padding),
      child: SizedBox(
        width: messageMedias.length > 1 || repliedEventMessage != null ? double.infinity : 146.0.s,
        child: Column(
          children: [
            if (repliedMessageItem != null)
              ReplyMessage(messageItem, repliedMessageItem, onTapReply),
            VisualMediaCustomGrid(
              eventMessage: eventMessage,
              messageMedias: messageMedias,
            ),
            VisualMediaMetadata(eventMessage: eventMessage),
          ],
        ),
      ),
    );
  }
}
