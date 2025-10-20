// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/providers/user_chat_privacy_provider.r.dart';
import 'package:ion/app/features/chat/views/components/chat_privacy_tooltip.dart';
import 'package:ion/app/features/search/model/chat_search_result_item.f.dart';
import 'package:ion/app/features/search/providers/chat_search/chat_search_history_provider.m.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';

class ChatSearchResultListItem extends HookConsumerWidget {
  const ChatSearchResultListItem({
    required this.showLastMessage,
    required this.item,
    super.key,
  });

  final bool showLastMessage;
  final ChatSearchResultItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(
      userPreviewDataProvider(item.masterPubkey, network: false)
          .select(userPreviewDisplayNameSelector),
    );

    final username = ref.watch(
      userPreviewDataProvider(item.masterPubkey, network: false).select(userPreviewNameSelector),
    );

    final canSendMessage =
        ref.watch(canSendMessageProvider(item.masterPubkey, network: false)).valueOrNull ?? false;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: canSendMessage
          ? () {
              ref.read(chatSearchHistoryProvider.notifier).addUserIdToTheHistory(item.masterPubkey);
              context.pushReplacement(
                ConversationRoute(receiverMasterPubkey: item.masterPubkey).location,
              );
            }
          : null,
      child: ChatPrivacyTooltip(
        canSendMessage: canSendMessage,
        child: BadgesUserListItem(
          contentPadding: EdgeInsets.symmetric(
            vertical: 8.0.s,
            horizontal: ScreenSideOffset.defaultSmallMargin,
          ),
          masterPubkey: item.masterPubkey,
          title: Padding(
            padding: EdgeInsetsDirectional.only(bottom: 2.38.s),
            child: Text(
              displayName,
              style: context.theme.appTextThemes.subtitle3.copyWith(
                color: context.theme.appColors.primaryText,
              ),
              strutStyle: const StrutStyle(forceStrutHeight: true),
            ),
          ),
          constraints: BoxConstraints(minHeight: 48.0.s),
          subtitle: item.lastMessageContent.isNotEmpty && showLastMessage
              ? Text(
                  item.lastMessageContent!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.appTextThemes.body2.copyWith(
                    color: context.theme.appColors.onTertiaryBackground,
                  ),
                )
              : Text(
                  prefixUsername(username: username, context: context),
                  style: context.theme.appTextThemes.body2.copyWith(
                    color: context.theme.appColors.onTertiaryBackground,
                  ),
                ),
          avatarSize: 48.0.s,
          leadingPadding: EdgeInsetsDirectional.only(end: 12.0.s),
          trailing: Assets.svg.iconArrowRight.icon(
            size: 24.0.s,
            color: context.theme.appColors.tertiaryText,
          ),
        ),
      ),
    );
  }
}
