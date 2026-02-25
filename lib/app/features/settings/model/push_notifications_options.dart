// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/push_notifications/data/models/push_notification_category.dart';
import 'package:ion/app/features/settings/model/selectable_option.dart';
import 'package:ion/generated/assets.gen.dart';

abstract interface class PushNotificationOption {
  PushNotificationCategory get category;
}

enum SocialNotificationOption implements SelectableOption, PushNotificationOption {
  posts,
  mentionsAndReplies,
  reposts,
  likes,
  newFollowers;

  @override
  String getLabel(BuildContext context) => switch (this) {
        SocialNotificationOption.posts => context.i18n.push_notification_social_option_posts,
        SocialNotificationOption.mentionsAndReplies =>
          context.i18n.push_notification_social_option_mentions_replies,
        SocialNotificationOption.reposts => context.i18n.push_notification_social_option_reposts,
        SocialNotificationOption.likes => context.i18n.push_notification_social_option_likes,
        SocialNotificationOption.newFollowers =>
          context.i18n.push_notification_social_option_new_followers,
      };

  @override
  Widget getIcon(BuildContext context) {
    final icon = switch (this) {
      SocialNotificationOption.posts => Assets.svg.iconProfileFeed,
      SocialNotificationOption.mentionsAndReplies => Assets.svg.iconFieldNickname,
      SocialNotificationOption.reposts => Assets.svg.iconFeedRepost,
      SocialNotificationOption.likes => Assets.svg.iconVideoLikeOff,
      SocialNotificationOption.newFollowers => Assets.svg.iconSearchFollow,
    };

    return icon.icon(color: context.theme.appColors.primaryAccent);
  }

  @override
  PushNotificationCategory get category => switch (this) {
        SocialNotificationOption.posts => PushNotificationCategory.posts,
        SocialNotificationOption.mentionsAndReplies => PushNotificationCategory.mentionsAndReplies,
        SocialNotificationOption.reposts => PushNotificationCategory.reposts,
        SocialNotificationOption.likes => PushNotificationCategory.likes,
        SocialNotificationOption.newFollowers => PushNotificationCategory.newFollowers,
      };
}

enum TokenizedCommunityNotificationOption implements SelectableOption, PushNotificationOption {
  creatorToken,
  contentToken,
  creatorTokenTrades,
  contentTokenTrades,
  tokenUpdates;

  @override
  String getLabel(BuildContext context) => switch (this) {
        TokenizedCommunityNotificationOption.creatorToken =>
          context.i18n.push_notification_tc_option_creator_token,
        TokenizedCommunityNotificationOption.contentToken =>
          context.i18n.push_notification_tc_option_content_token,
        TokenizedCommunityNotificationOption.creatorTokenTrades =>
          context.i18n.push_notification_tc_option_creator_token_trades,
        TokenizedCommunityNotificationOption.contentTokenTrades =>
          context.i18n.push_notification_tc_option_content_token_trades,
        TokenizedCommunityNotificationOption.tokenUpdates =>
          context.i18n.push_notification_tc_option_token_updates,
      };

  @override
  Widget getIcon(BuildContext context) {
    final icon = switch (this) {
      TokenizedCommunityNotificationOption.creatorToken => Assets.svg.iconSearchCreatonewrtoken,
      TokenizedCommunityNotificationOption.contentToken => Assets.svg.iconSearchContenttoken,
      TokenizedCommunityNotificationOption.creatorTokenTrades => Assets.svg.iconSearchCreatortrades,
      TokenizedCommunityNotificationOption.contentTokenTrades => Assets.svg.iconSearchContenttrades,
      TokenizedCommunityNotificationOption.tokenUpdates => Assets.svg.iconTokenupdates,
    };

    return icon.icon(color: context.theme.appColors.primaryAccent);
  }

  @override
  PushNotificationCategory get category => switch (this) {
        TokenizedCommunityNotificationOption.creatorToken => PushNotificationCategory.creatorToken,
        TokenizedCommunityNotificationOption.contentToken => PushNotificationCategory.contentToken,
        TokenizedCommunityNotificationOption.creatorTokenTrades =>
          PushNotificationCategory.creatorTokenTrades,
        TokenizedCommunityNotificationOption.contentTokenTrades =>
          PushNotificationCategory.contentTokenTrades,
        TokenizedCommunityNotificationOption.tokenUpdates => PushNotificationCategory.tokenUpdates,
      };
}

enum ChatNotificationOption implements SelectableOption, PushNotificationOption {
  directMessages,
  groupChats,
  channels,
  paymentRequest,
  paymentReceived;

  @override
  String getLabel(BuildContext context) => switch (this) {
        ChatNotificationOption.directMessages =>
          context.i18n.push_notification_chat_option_direct_messages,
        ChatNotificationOption.groupChats => context.i18n.push_notification_chat_option_group_chats,
        ChatNotificationOption.channels => context.i18n.push_notification_chat_option_channels,
        ChatNotificationOption.paymentRequest =>
          context.i18n.push_notification_chat_option_payment_request,
        ChatNotificationOption.paymentReceived =>
          context.i18n.push_notification_chat_option_payment_received,
      };

  @override
  Widget getIcon(BuildContext context) {
    final icon = switch (this) {
      ChatNotificationOption.directMessages => Assets.svg.iconChatOff,
      ChatNotificationOption.groupChats => Assets.svg.iconSearchGroups,
      ChatNotificationOption.channels => Assets.svg.iconSearchChannel,
      ChatNotificationOption.paymentRequest => Assets.svg.iconButtonAddstroke,
      ChatNotificationOption.paymentReceived => Assets.svg.iconButtonReceive,
    };

    return icon.icon(color: context.theme.appColors.primaryAccent);
  }

  @override
  PushNotificationCategory get category => switch (this) {
        ChatNotificationOption.directMessages => PushNotificationCategory.directMessages,
        ChatNotificationOption.groupChats => PushNotificationCategory.groupChats,
        ChatNotificationOption.channels => PushNotificationCategory.channels,
        ChatNotificationOption.paymentRequest => PushNotificationCategory.messagePaymentRequest,
        ChatNotificationOption.paymentReceived => PushNotificationCategory.messagePaymentReceived,
      };
}

enum SystemNotificationOption implements SelectableOption, PushNotificationOption {
  updates;

  @override
  String getLabel(BuildContext context) => context.i18n.push_notification_system_option_update;

  @override
  Widget getIcon(BuildContext context) {
    return Assets.svg.iconNotificationsUpdates.icon(color: context.theme.appColors.primaryAccent);
  }

  @override
  PushNotificationCategory get category => PushNotificationCategory.updates;
}
