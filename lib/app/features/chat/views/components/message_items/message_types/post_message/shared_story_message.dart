// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/hooks/use_has_reaction.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_item_wrapper/message_item_wrapper.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_reactions/message_reactions.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_types/text_message/text_message.dart';
import 'package:ion/app/features/components/ion_connect_network_image/ion_connect_network_image.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/stories/providers/story_image_loading_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/story_viewing_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_media_content.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class SharedStoryMessage extends HookConsumerWidget {
  const SharedStoryMessage({
    required this.storyEntity,
    required this.replyEventMessage,
    this.margin,
    super.key,
  });

  final IonConnectEntity storyEntity;
  final EventMessage replyEventMessage;
  final EdgeInsetsDirectional? margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);

    final isMe = ref.watch(isCurrentUserSelectorProvider(replyEventMessage.masterPubkey));

    final storyEntityData = useMemoized(
      () => switch (storyEntity) {
        final ModifiablePostEntity post => post.data,
        final PostEntity post => post.data,
        _ => null,
      },
    );

    final storyMedia = useMemoized(
      () => switch (storyEntityData) {
        final EntityDataWithMediaContent data => data.media.values.firstOrNull,
        _ => null,
      },
    );

    if (storyMedia == null) {
      return _UnavailableStoryContainer(isMe: isMe, replyEventMessage: replyEventMessage);
    }

    final storyUrl = useMemoized(
      () => (storyMedia.mediaType == MediaType.video ? storyMedia.thumb : storyMedia.url) ?? '',
    );

    final storyExpired = useMemoized(
      () => switch (storyEntity) {
        final ModifiablePostEntity post =>
          post.data.expiration!.value.toDateTime.isBefore(DateTime.now()),
        final PostEntity post => post.data.expiration!.value.toDateTime.isBefore(DateTime.now()),
        _ => true,
      },
    );

    final storyBelongsToCurrentUser = storyEntity.masterPubkey != currentUserMasterPubkey;

    final storyDeleted = useMemoized(
      () => switch (storyEntity) {
        final ModifiablePostEntity post => post.isDeleted,
        _ => false,
      },
    );

    final isReplyToStory =
        useHasReaction(replyEventMessage, ref) || replyEventMessage.content.isNotEmpty;

    return Container(
      margin: margin,
      child: Align(
        alignment: isMe ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
        child: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                if (storyExpired) return;

                var storyViewerState = ref.read(
                  userStoriesViewingNotifierProvider(
                    storyEntity.masterPubkey,
                    showOnlySelectedUser: true,
                  ),
                );

                if (storyViewerState.userStories.isEmpty) {
                  await ref
                      .read(
                        userStoriesViewingNotifierProvider(
                          storyEntity.masterPubkey,
                          showOnlySelectedUser: true,
                        ).notifier,
                      )
                      .setUserStoryByReference(storyEntity.toEventReference());

                  storyViewerState = ref.read(
                    userStoriesViewingNotifierProvider(
                      storyEntity.masterPubkey,
                      showOnlySelectedUser: true,
                    ),
                  );
                }

                if (context.mounted && storyViewerState.userStories.isNotEmpty) {
                  unawaited(
                    StoryViewerRoute(
                      pubkey: storyEntity.masterPubkey,
                      initialStoryReference: storyEntity.toEventReference().encode(),
                    ).push<void>(context),
                  );
                }
              },
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (isReplyToStory) _SenderReceiverLabel(isMe: isMe),
                  if (storyBelongsToCurrentUser ||
                      (storyUrl.isNotEmpty && !storyDeleted && !storyExpired))
                    _StoryPreviewImage(
                      isMe: isMe,
                      storyUrl: storyUrl,
                      replyEventMessage: replyEventMessage,
                      isThumb: storyMedia.mediaType == MediaType.video,
                    )
                  else
                    _UnavailableStoryContainer(isMe: isMe, replyEventMessage: replyEventMessage),
                  if (replyEventMessage.content.isNotEmpty)
                    Padding(
                      padding: EdgeInsetsDirectional.only(top: 4.0.s),
                      child: TextMessage(eventMessage: replyEventMessage),
                    ),
                ],
              ),
            ),
            if (storyUrl.isNotEmpty && replyEventMessage.content.isEmpty)
              PositionedDirectional(
                start: 6.0.s,
                bottom: 6.0.s,
                child: IgnorePointer(
                  child: MessageReactions(eventMessage: replyEventMessage, isMe: isMe),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SenderReceiverLabel extends StatelessWidget {
  const _SenderReceiverLabel({required this.isMe});

  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Text(
      isMe ? context.i18n.story_reply_sender : context.i18n.story_reply_receiver,
      style: context.theme.appTextThemes.caption3.copyWith(
        color: context.theme.appColors.quaternaryText,
      ),
    );
  }
}

class _StoryPreviewImage extends HookConsumerWidget {
  const _StoryPreviewImage({
    required this.isMe,
    required this.storyUrl,
    required this.replyEventMessage,
    required this.isThumb,
  });

  final bool isMe;
  final bool isThumb;
  final String storyUrl;
  final EventMessage replyEventMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheManager = ref.watch(storyImageCacheManagerProvider);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0.s),
      child: IonConnectNetworkImage(
        cacheManager: cacheManager,
        imageUrl: storyUrl,
        height: 220.0.s,
        authorPubkey: replyEventMessage.masterPubkey,
        imageBuilder: (_, imageProvider) => Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Image(image: imageProvider),
            if (isThumb)
              Assets.svg.iconVideoPlay.icon(
                color: context.theme.appColors.onPrimaryAccent,
                size: 32.0.s,
              ),
          ],
        ),
        errorWidget: (context, url, error) =>
            _UnavailableStoryContainer(isMe: isMe, replyEventMessage: replyEventMessage),
      ),
    );
  }
}

class _UnavailableStoryContainer extends StatelessWidget {
  const _UnavailableStoryContainer({required this.isMe, required this.replyEventMessage});

  final bool isMe;
  final EventMessage replyEventMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 6.0.s,
        horizontal: 6.0.s,
      ),
      constraints: BoxConstraints(
        maxWidth: MessageItemWrapper.maxWidth,
      ),
      decoration: BoxDecoration(
        color:
            isMe ? context.theme.appColors.primaryAccent : context.theme.appColors.onPrimaryAccent,
        borderRadius: BorderRadiusDirectional.all(
          Radius.circular(12.0.s),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Assets.svg.iconFeedStories.icon(
                color: isMe
                    ? context.theme.appColors.onPrimaryAccent
                    : context.theme.appColors.quaternaryText,
              ),
              SizedBox(width: 4.0.s),
              Text(
                isMe
                    ? context.i18n.story_reply_not_available_sender
                    : context.i18n.story_reply_not_available_receiver,
                style: context.theme.appTextThemes.caption3.copyWith(
                  color: isMe
                      ? context.theme.appColors.onPrimaryAccent
                      : context.theme.appColors.quaternaryText,
                ),
              ),
            ],
          ),
          MessageReactions(eventMessage: replyEventMessage, isMe: isMe),
        ],
      ),
    );
  }
}
