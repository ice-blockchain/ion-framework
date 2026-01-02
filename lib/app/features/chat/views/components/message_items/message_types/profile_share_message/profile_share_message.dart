// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
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
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user/model/user_preview_data.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/username.dart';

class ProfileShareMessage extends HookConsumerWidget {
  const ProfileShareMessage({
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
    final isMe = ref.watch(isCurrentUserSelectorProvider(eventMessage.masterPubkey));

    final entity = useMemoized(
      () => ReplaceablePrivateDirectMessageEntity.fromEventMessage(eventMessage),
      [eventMessage],
    );

    final profilePubkey = useMemoized(
      () => EventReference.fromEncoded(entity.data.content).masterPubkey,
      [entity],
    );

    final hasReactions = useHasReaction(entity.toEventReference(), ref);

    final userMetadata = ref.watch(userPreviewDataProvider(profilePubkey)).valueOrNull;

    final messageItem = ShareProfileItem(
      eventMessage: eventMessage,
      contentDescription: userMetadata?.data.name ?? '',
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

    if (userMetadata == null) {
      return const SizedBox.shrink();
    }

    return MessageItemWrapper(
      isMe: isMe,
      margin: margin,
      messageItem: messageItem,
      contentPadding: EdgeInsets.all(12.0.s),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (repliedMessageItem != null)
              ReplyMessage(messageItem, repliedMessageItem, onTapReply),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProfileSummary(isMe: isMe, userMetadata: userMetadata),
                          SizedBox(height: 8.0.s),
                          Button.compact(
                            type: ButtonType.outlined,
                            backgroundColor: context.theme.appColors.tertiaryBackground,
                            onPressed: () {
                              ProfileRoute(pubkey: profilePubkey).push<void>(context);
                            },
                            minimumSize: Size(120.0.s, 32.0.s),
                            label: Padding(
                              padding: EdgeInsetsDirectional.only(bottom: 2.0.s),
                              child: Text(
                                context.i18n.chat_profile_view_button,
                                style: context.theme.appTextThemes.caption2.copyWith(
                                  color: context.theme.appColors.primaryText,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      MessageReactions(eventMessage: eventMessage, isMe: isMe),
                    ],
                  ),
                ),
                MessageMetadata(
                  eventMessage: eventMessage,
                  startPadding: hasReactions ? 0.0.s : 8.0.s,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({
    required this.isMe,
    required this.userMetadata,
  });

  final bool isMe;
  final UserPreviewEntity userMetadata;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: BadgesUserListItem(
        title: Text(
          userMetadata.data.trimmedDisplayName,
          style: context.theme.appTextThemes.subtitle3.copyWith(
            color: isMe
                ? context.theme.appColors.onPrimaryAccent
                : context.theme.appColors.primaryText,
          ),
        ),
        subtitle: Text(
          prefixUsername(username: userMetadata.data.name, context: context),
          style: context.theme.appTextThemes.body2.copyWith(
            color: isMe
                ? context.theme.appColors.onPrimaryAccent
                : context.theme.appColors.onTertiaryBackground,
          ),
        ),
        masterPubkey: userMetadata.masterPubkey,
        avatarSize: 40.0.s,
      ),
    );
  }
}
