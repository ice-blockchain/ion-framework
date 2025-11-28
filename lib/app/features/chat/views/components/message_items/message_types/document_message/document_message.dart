// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/chat_medias_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/chat_message_media_path_provider.r.dart';
import 'package:ion/app/features/chat/hooks/use_has_reaction.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/model/message_list_item.f.dart';
import 'package:ion/app/features/chat/recent_chats/providers/replied_message_list_item_provider.r.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_item_wrapper/message_item_wrapper.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_metadata/message_metadata.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_reactions/message_reactions.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_types/reply_message/reply_message.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/services/share/share.dart';
import 'package:ion/app/utils/file.dart';
import 'package:ion/app/utils/filesize.dart';
import 'package:ion/generated/assets.gen.dart';

class DocumentMessage extends HookConsumerWidget {
  const DocumentMessage({
    required this.eventMessage,
    this.margin,
    this.onTapReply,
    super.key,
  });

  final VoidCallback? onTapReply;
  final EventMessage eventMessage;
  final EdgeInsetsDirectional? margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMe = ref.watch(isCurrentUserSelectorProvider(eventMessage.masterPubkey));

    final entity = useMemoized(
      () => ReplaceablePrivateDirectMessageEntity.fromEventMessage(eventMessage),
      [eventMessage],
    );

    final eventReference = entity.toEventReference();

    final messageMedia = ref.watch(
          chatMediasProvider(eventReference: eventReference).select((value) {
            final media = value.valueOrNull;

            if (media != null && media.isNotEmpty) {
              ListCachedObjects.updateObject<MessageMediaTableData>(
                context,
                media.first,
              );

              return media.first;
            }
            return null;
          }),
        ) ??
        ListCachedObjects.maybeObjectOf<MessageMediaTableData>(context, eventReference);

    final mediaAttachment = entity.data.primaryMedia;

    final localMediaPath = ref
            .watch(
              chatMessageMediaPathProvider(
                entity: entity,
                loadThumbnail: false,
                cacheKey: messageMedia?.cacheKey,
                mediaAttachment: mediaAttachment,
              ).select((value) {
                final documentPath = value.valueOrNull;
                if (documentPath != null) {
                  ListCachedObjects.updateObject<PathWithKey>(
                    context,
                    (key: eventReference.toString(), filePath: documentPath),
                  );
                }
                return value;
              }),
            )
            .valueOrNull ??
        ListCachedObjects.maybeObjectOf<PathWithKey>(context, eventReference.toString())?.filePath;

    final fileSizeInFormat = localMediaPath != null ? formattedFileSize(localMediaPath) : '';

    final hasReactions = useHasReaction(eventReference, ref);

    final messageItem = useMemoized(
      () => DocumentItem(
        eventMessage: eventMessage,
        contentDescription: mediaAttachment?.alt ?? '',
      ),
      [eventMessage, mediaAttachment?.alt],
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

    if (messageMedia == null) {
      return const SizedBox.shrink();
    }

    return MessageItemWrapper(
      isMe: isMe,
      margin: margin,
      messageItem: messageItem,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 12.0.s,
        vertical: 12.0.s,
      ),
      child: Column(
        children: [
          if (repliedMessageItem != null) ReplyMessage(messageItem, repliedMessageItem, onTapReply),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              if (localMediaPath != null) {
                final fileName = mediaAttachment?.alt ?? '';
                final opened = await openFile(localMediaPath);
                if (!opened) {
                  await shareFile(localMediaPath, name: fileName);
                }
              }
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _DocumentIcon(
                            isLoading: messageMedia.status == MessageMediaStatus.processing,
                          ),
                          SizedBox(
                            width: 12.0.s,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  mediaAttachment?.alt ?? '',
                                  style: context.theme.appTextThemes.body2.copyWith(
                                    color: isMe
                                        ? context.theme.appColors.onPrimaryAccent
                                        : context.theme.appColors.primaryText,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                Text(
                                  fileSizeInFormat ?? '',
                                  style: context.theme.appTextThemes.caption2.copyWith(
                                    color: isMe
                                        ? context.theme.appColors.onPrimaryAccent
                                        : context.theme.appColors.primaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      MessageReactions(
                        isMe: isMe,
                        eventMessage: eventMessage,
                      ),
                    ],
                  ),
                ),
                MessageMetadata(
                  eventMessage: eventMessage,
                  startPadding: hasReactions ? 0.0.s : 8.0.s,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentIcon extends StatelessWidget {
  const _DocumentIcon({
    required this.isLoading,
  });

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0.s),
      decoration: BoxDecoration(
        color: context.theme.appColors.tertiaryBackground,
        borderRadius: BorderRadius.circular(12.0.s),
        border: Border.all(
          color: context.theme.appColors.onTertiaryFill,
          width: 1.0.s,
        ),
      ),
      child: isLoading
          ? const IONLoadingIndicator(
              type: IndicatorType.dark,
            )
          : Assets.svg.iconFeedAddfile.icon(
              size: 20.0.s,
              color: context.theme.appColors.primaryAccent,
            ),
    );
  }
}
