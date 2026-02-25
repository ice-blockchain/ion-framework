// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/ion_connect_avatar/ion_connect_avatar.dart';
import 'package:ion/app/features/feed/notifications/data/model/ion_notification.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_icons/outlined_notification_icon.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_icons/token_notification_icon.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_icons/token_transaction_icon.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class NotificationIcons extends StatelessWidget {
  const NotificationIcons({
    required this.notification,
    super.key,
  });

  final IonNotification notification;

  static double get separator => 4.0.s;

  static int get visibleIconsCount => 10;

  @override
  Widget build(BuildContext context) {
    final iconSize = ((MediaQuery.sizeOf(context).width - ScreenSideOffset.defaultSmallMargin * 2) -
            separator * (visibleIconsCount - 1)) /
        (visibleIconsCount + 0.5); // last icon should be half visible as a hint to scroll option

    return Row(
      children: [
        _getNotificationIcon(context, size: iconSize),
        SizedBox(width: separator / 2),
        Expanded(
          child: SizedBox(
            height: iconSize,
            child: ListView.separated(
              padding: EdgeInsetsGeometry.directional(start: separator / 2),
              scrollDirection: Axis.horizontal,
              itemCount: notification.pubkeys.length,
              separatorBuilder: (context, index) => SizedBox(width: separator),
              itemBuilder: (context, index) {
                final pubkey = notification.pubkeys[index];
                return GestureDetector(
                  key: ValueKey(pubkey),
                  onTap: () => ProfileRoute(pubkey: pubkey).push<void>(context),
                  child: IonConnectAvatar(
                    size: iconSize,
                    fit: BoxFit.cover,
                    masterPubkey: pubkey,
                    borderRadius: BorderRadius.circular(10.0.s),
                    network: true,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _getNotificationIcon(BuildContext context, {required double size}) {
    return switch (notification) {
      final CommentIonNotification comment => switch (comment.type) {
          CommentIonNotificationType.reply => OutlinedNotificationIcon(
              size: size,
              asset: Assets.svg.iconBlockComment,
              backgroundColor: context.theme.appColors.purple,
            ),
          CommentIonNotificationType.quote => OutlinedNotificationIcon(
              size: size,
              asset: Assets.svg.iconFeedQuote,
              backgroundColor: context.theme.appColors.medBlue,
            ),
          CommentIonNotificationType.repost => OutlinedNotificationIcon(
              size: size,
              asset: Assets.svg.iconFeedRepost,
              backgroundColor: context.theme.appColors.pink,
            ),
        },
      MentionIonNotification() => OutlinedNotificationIcon(
          size: size,
          asset: Assets.svg.iconNotificationMention,
          backgroundColor: context.theme.appColors.lightBlue,
        ),
      LikesIonNotification() => OutlinedNotificationIcon(
          size: size,
          asset: Assets.svg.iconVideoLikeOff,
          backgroundColor: context.theme.appColors.attentionRed,
        ),
      FollowersIonNotification() => OutlinedNotificationIcon(
          size: size,
          asset: Assets.svg.iconSearchFollow,
          backgroundColor: context.theme.appColors.primaryAccent,
        ),
      final ContentIonNotification content => OutlinedNotificationIcon(
          size: size,
          asset: switch (content.type) {
            ContentIonNotificationType.posts => Assets.svg.iconBlockComment,
            ContentIonNotificationType.stories => Assets.svg.iconFeedStories,
            ContentIonNotificationType.articles => Assets.svg.iconFeedArticles,
            ContentIonNotificationType.videos => Assets.svg.iconFeedVideos,
          },
          backgroundColor: switch (content.type) {
            ContentIonNotificationType.posts => context.theme.appColors.purple,
            ContentIonNotificationType.stories => context.theme.appColors.orangePeel,
            ContentIonNotificationType.articles => context.theme.appColors.success,
            ContentIonNotificationType.videos => context.theme.appColors.lossRed,
          },
        ),
      TokenLaunchIonNotification() => TokenNotificationIcon(size: size),
      final TokenTransactionIonNotification tokenTransaction => TokenTransactionIcon(
          size: size,
          eventReference: tokenTransaction.eventReference,
        ),
    };
  }
}
