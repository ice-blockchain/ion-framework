// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/notifications/data/model/ion_notification.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/comment_notification_info.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/content_notification_info.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/followers_notification_info.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/likes_notification_info.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/mention_notification_info.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/token_buying_activity_notification_info.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/token_launch_notification_info.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/token_price_change_notification_info.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/token_transaction_notification_info.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/token_trending_notification_info.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/token_buying_activity_response.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/token_price_change_response.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/tokens_global_stat_response.f.dart';

class NotificationInfo extends ConsumerWidget {
  const NotificationInfo({
    required this.notification,
    super.key,
  });

  final IonNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (notification) {
      final LikesIonNotification notification => LikesNotificationInfo(notification: notification),
      final FollowersIonNotification notification =>
        FollowersNotificationInfo(notification: notification),
      final CommentIonNotification notification =>
        CommentNotificationInfo(notification: notification),
      final MentionIonNotification notification =>
        MentionNotificationInfo(notification: notification),
      final ContentIonNotification notification =>
        ContentNotificationInfo(notification: notification),
      final TokenLaunchIonNotification notification =>
        TokenLaunchNotificationInfo(notification: notification),
      final TokenTransactionIonNotification notification =>
        TokenTransactionNotificationInfo(notification: notification),
      final TokenUpdateIonNotification notification => switch (notification.entity) {
          final TokenBuyingActivityResponseEntity entity =>
            TokenBuyingActivityNotificationInfo(entity: entity, timestamp: notification.timestamp),
          final TokenPriceChangeResponseEntity entity =>
            TokenPriceChangeNotificationInfo(entity: entity, timestamp: notification.timestamp),
          final TokenGlobalStatResponseEntity entity =>
            TokenTrendingNotificationInfo(entity: entity, timestamp: notification.timestamp),
          _ => const SizedBox.shrink(),
        }
    };
  }
}
