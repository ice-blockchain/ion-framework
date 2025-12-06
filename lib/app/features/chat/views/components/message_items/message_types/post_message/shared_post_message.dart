// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/model/message_list_item.f.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_item_wrapper/message_item_wrapper.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_reactions/message_reactions.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/providers/parsed_media_provider.r.dart';
import 'package:ion/app/features/feed/views/components/article/article.dart';
import 'package:ion/app/features/feed/views/components/post/post.dart';
import 'package:ion/app/features/feed/views/components/user_info/user_info.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_media_content.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class SharedPostMessage extends HookConsumerWidget {
  const SharedPostMessage({
    required this.onTapReply,
    required this.postEntity,
    required this.sharedEventMessage,
    this.margin,
    super.key,
  });

  final VoidCallback? onTapReply;
  final IonConnectEntity postEntity;
  final EventMessage sharedEventMessage;
  final EdgeInsetsDirectional? margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMe = ref.watch(isCurrentUserSelectorProvider(sharedEventMessage.masterPubkey));

    final postData = useMemoized(
      () => switch (postEntity) {
        final PostEntity post => post.data,
        final ArticleEntity article => article.data,
        final ModifiablePostEntity post => post.data,
        _ => false,
      },
      [postEntity],
    );

    final createdAt = useMemoized(
      () => switch (postEntity) {
        final PostEntity post => post.createdAt,
        final ArticleEntity article => article.data.publishedAt.value,
        final ModifiablePostEntity post => post.data.publishedAt.value,
        _ => DateTime.now().microsecondsSinceEpoch,
      },
      [postEntity],
    );

    final postEntityEventReference = postEntity.toEventReference();

    final postFromNetwork = ref.watch(
          ionConnectEntityProvider(
            cache: false,
            eventReference: postEntityEventReference,
          ).select((value) {
            final entity = value.valueOrNull;
            if (entity != null) {
              ListCachedObjects.updateObject<IonConnectEntity>(context, entity);
            }
            return entity;
          }),
        ) ??
        ListCachedObjects.maybeObjectOf<IonConnectEntity>(context, postEntityEventReference);

    final isPostDeleted = useMemoized(
      () => switch (postFromNetwork) {
        final ArticleEntity article => article.isDeleted,
        final ModifiablePostEntity post => post.isDeleted,
        _ => false,
      },
      [postFromNetwork],
    );

    if (postData is! EntityDataWithMediaContent || isPostDeleted) {
      return const SizedBox.shrink();
    }

    final result = ref.watch(cachedParsedMediaProvider(postData));
    final content = result.valueOrNull?.content;
    final media = result.valueOrNull?.media ?? [];
    if (content == null) return const SizedBox.shrink();

    final contentAsPlainText = useMemoized(
      () => Document.fromDelta(content).toPlainText().trim(),
      [content],
    );

    final messageItem = useMemoized(
      () => PostItem(
        medias: media,
        eventMessage: sharedEventMessage,
        contentDescription:
            contentAsPlainText.isEmpty ? context.i18n.post_page_title : contentAsPlainText,
      ),
      [media, sharedEventMessage, contentAsPlainText],
    );

    final userInfo = UserInfo(
      accentTheme: isMe,
      createdAt: createdAt,
      pubkey: postEntity.masterPubkey,
      network: true,
      textStyle: isMe
          ? context.theme.appTextThemes.caption.copyWith(
              color: context.theme.appColors.onPrimaryAccent,
            )
          : null,
    );

    return MessageItemWrapper(
      isMe: isMe,
      margin: margin,
      messageItem: messageItem,
      contentPadding: EdgeInsets.symmetric(horizontal: 0.0.s, vertical: 12.0.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (postEntity is ArticleEntity)
            GestureDetector(
              onTap: () =>
                  ArticleDetailsRoute(eventReference: postEntity.toEventReference().encode())
                      .push<void>(context),
              behavior: HitTestBehavior.opaque,
              child: Article(
                header:
                    Padding(padding: EdgeInsetsDirectional.only(bottom: 10.0.s), child: userInfo),
                isAccentTheme: isMe,
                footer: const SizedBox.shrink(),
                eventReference: postEntity.toEventReference(),
              ),
            )
          else
            GestureDetector(
              onTap: () => PostDetailsRoute(eventReference: postEntity.toEventReference().encode())
                  .push<void>(context),
              behavior: HitTestBehavior.opaque,
              child: Post(
                header:
                    Padding(padding: EdgeInsetsDirectional.only(start: 14.0.s), child: userInfo),
                isAccentTheme: isMe,
                footer: const SizedBox.shrink(),
                eventReference: postEntity.toEventReference(),
                quotedEventFooter: const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.0.s, vertical: 0.0.s),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: MessageReactions(eventMessage: sharedEventMessage, isMe: isMe),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
