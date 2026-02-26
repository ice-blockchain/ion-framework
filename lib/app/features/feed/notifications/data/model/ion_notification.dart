// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/notifications/views/notification_icon/outlined_notification_icon.dart';
import 'package:ion/app/features/feed/notifications/views/notification_icon/token_notification_icon.dart';
import 'package:ion/app/features/feed/notifications/views/notification_icon/token_transaction_icon.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/generated/assets.gen.dart';

sealed class IonNotification {
  IonNotification({required this.timestamp, required this.pubkeys});

  final DateTime timestamp;

  final List<String> pubkeys;

  Widget getIcon(BuildContext context, {required double size});
}

enum CommentIonNotificationType { reply, quote, repost }

final class CommentIonNotification extends IonNotification {
  CommentIonNotification({
    required this.type,
    required this.eventReference,
    required super.timestamp,
  }) : super(pubkeys: [eventReference.masterPubkey]);

  final CommentIonNotificationType type;

  final EventReference eventReference;

  @override
  Widget getIcon(BuildContext context, {required double size}) {
    return switch (type) {
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
    };
  }
}

final class MentionIonNotification extends IonNotification {
  MentionIonNotification({
    required this.eventReference,
    required super.timestamp,
  }) : super(pubkeys: [eventReference.masterPubkey]);

  final EventReference eventReference;

  @override
  Widget getIcon(BuildContext context, {required double size}) => OutlinedNotificationIcon(
        size: size,
        asset: Assets.svg.iconNotificationMention,
        backgroundColor: context.theme.appColors.lightBlue,
      );
}

final class LikesIonNotification extends IonNotification {
  LikesIonNotification({
    required this.eventReference,
    required this.total,
    required super.timestamp,
    required super.pubkeys,
  });

  final EventReference eventReference;

  final int total;

  @override
  Widget getIcon(BuildContext context, {required double size}) => OutlinedNotificationIcon(
        size: size,
        asset: Assets.svg.iconVideoLikeOff,
        backgroundColor: context.theme.appColors.attentionRed,
      );
}

final class FollowersIonNotification extends IonNotification {
  FollowersIonNotification({
    required this.total,
    required super.timestamp,
    required super.pubkeys,
  });

  final int total;

  @override
  Widget getIcon(BuildContext context, {required double size}) => OutlinedNotificationIcon(
        size: size,
        asset: Assets.svg.iconSearchFollow,
        backgroundColor: context.theme.appColors.primaryAccent,
      );
}

enum ContentIonNotificationType { posts, stories, articles, videos }

final class ContentIonNotification extends IonNotification {
  ContentIonNotification({
    required this.type,
    required this.eventReference,
    required super.timestamp,
  }) : super(pubkeys: [eventReference.masterPubkey]);

  final ContentIonNotificationType type;

  final EventReference eventReference;

  @override
  Widget getIcon(BuildContext context, {required double size}) => OutlinedNotificationIcon(
        size: size,
        asset: switch (type) {
          ContentIonNotificationType.posts => Assets.svg.iconBlockComment,
          ContentIonNotificationType.stories => Assets.svg.iconFeedStories,
          ContentIonNotificationType.articles => Assets.svg.iconFeedArticles,
          ContentIonNotificationType.videos => Assets.svg.iconFeedVideos,
        },
        backgroundColor: switch (type) {
          ContentIonNotificationType.posts => context.theme.appColors.purple,
          ContentIonNotificationType.stories => context.theme.appColors.orangePeel,
          ContentIonNotificationType.articles => context.theme.appColors.success,
          ContentIonNotificationType.videos => context.theme.appColors.lossRed,
        },
      );
}

final class TokenLaunchIonNotification extends IonNotification {
  TokenLaunchIonNotification({
    required this.eventReference,
    required super.timestamp,
  }) : super(pubkeys: [eventReference.masterPubkey]);

  final EventReference eventReference;

  @override
  Widget getIcon(BuildContext context, {required double size}) => TokenNotificationIcon(size: size);
}

final class TokenTransactionIonNotification extends IonNotification {
  TokenTransactionIonNotification({
    required this.eventReference,
    required super.timestamp,
  }) : super(pubkeys: [eventReference.masterPubkey]);

  final EventReference eventReference;

  @override
  Widget getIcon(BuildContext context, {required double size}) =>
      TokenTransactionIcon(size: size, eventReference: eventReference);
}
