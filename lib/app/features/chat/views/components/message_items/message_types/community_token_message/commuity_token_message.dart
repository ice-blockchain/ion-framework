// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/hooks/use_has_reaction.dart';
import 'package:ion/app/features/chat/model/message_list_item.f.dart';
import 'package:ion/app/features/chat/recent_chats/providers/replied_message_list_item_provider.r.dart';
import 'package:ion/app/features/chat/views/components/message_items/components.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_reactions/message_reactions.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_types/reply_message/reply_message.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/feed_content_token.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/feed_profile_token.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/feed_twitter_token.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_type_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class CommunityTokenMessage extends HookConsumerWidget {
  const CommunityTokenMessage({
    required this.eventMessage,
    this.margin,
    this.onTapReply,
    this.definitionEntity,
    super.key,
  });

  final EventMessage eventMessage;
  final VoidCallback? onTapReply;
  final EdgeInsetsDirectional? margin;
  final CommunityTokenDefinitionEntity? definitionEntity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMe = ref.watch(isCurrentUserSelectorProvider(eventMessage.masterPubkey));

    final entity = useMemoized(
      () => ReplaceablePrivateDirectMessageEntity.fromEventMessage(eventMessage),
      [eventMessage],
    );

    final tokenType = definitionEntity != null
        ? ref.watch(tokenTypeForTokenDefinitionProvider(definitionEntity!)).valueOrNull
        : null;

    final hasReactions = useHasReaction(entity.toEventReference(), ref);

    final token = definitionEntity != null
        ? ref.watch(tokenMarketInfoProvider(definitionEntity!.data.externalAddress)).valueOrNull
        : null;

    final messageItem = CommunityTokenItem(
      eventMessage: eventMessage,
      contentDescription: tokenType != null ? tokenType.title(context) : '',
      icon: tokenType != null ? tokenType.icon(context) : '',
      imageUrl: token?.imageUrl,
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
      context: context,
    );

    return MessageItemWrapper(
      isMe: isMe,
      margin: margin,
      messageItem: messageItem,
      containerMaxWidth: 315.s,
      contentPadding: EdgeInsets.symmetric(horizontal: 12.0.s, vertical: 12.0.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (repliedMessageItem != null) ReplyMessage(messageItem, repliedMessageItem, onTapReply),
          if (definitionEntity case final definitionEntity?)
            GestureDetector(
              onTap: () {
                TokenizedCommunityRoute(
                  externalAddress: definitionEntity.data.externalAddress,
                ).push<void>(context);
              },
              child: _TokenCard(definitionEntity: definitionEntity),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MessageReactions(eventMessage: eventMessage, isMe: isMe),
              Padding(
                padding: EdgeInsetsDirectional.only(top: 6.0.s),
                child: MessageMetadata(
                  eventMessage: eventMessage,
                  startPadding: hasReactions ? 0.0.s : 8.0.s,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TokenCard extends ConsumerWidget {
  const _TokenCard({
    required this.definitionEntity,
  });

  final CommunityTokenDefinitionEntity definitionEntity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(tokenTypeForTokenDefinitionProvider(definitionEntity)).valueOrNull;

    if (type == null) {
      return const SizedBox.shrink();
    }

    final sidePadding = 0.0.s;

    if (type == CommunityContentTokenType.profile) {
      return FeedProfileToken(
        externalAddress: definitionEntity.data.externalAddress,
        sidePadding: sidePadding,
      );
    } else if (type == CommunityContentTokenType.twitter) {
      return FeedTwitterToken(
        externalAddress: definitionEntity.data.externalAddress,
        sidePadding: sidePadding,
      );
    } else {
      return FeedContentToken(
        type: type,
        tokenDefinition: definitionEntity,
        sidePadding: sidePadding,
      );
    }
  }
}
