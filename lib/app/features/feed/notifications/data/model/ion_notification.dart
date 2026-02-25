// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/notifications/views/notification_icon/outlined_notification_icon.dart';
import 'package:ion/app/features/feed/notifications/views/notification_icon/token_notification_icon.dart';
import 'package:ion/app/features/feed/notifications/views/notification_icon/token_transaction_icon.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/generated/assets.gen.dart';

sealed class IonNotification {
  IonNotification({required this.timestamp, required this.pubkeys});

  final DateTime timestamp;

  final List<String> pubkeys;

  Widget getIcon(BuildContext context, {required double size});

  String getDescription(BuildContext context);
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

  @override
  String getDescription(BuildContext context, [String typePhrase = '', bool isAuthor = false]) {
    return switch (type) {
      CommentIonNotificationType.reply => context.i18n.notifications_reply(typePhrase),
      CommentIonNotificationType.quote => context.i18n.notifications_share(typePhrase),
      CommentIonNotificationType.repost => context.i18n.notifications_repost(typePhrase),
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

  @override
  String getDescription(BuildContext context, [String eventTypeLabel = '']) {
    return context.i18n.notifications_mentioned;
  }
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

  @override
  String getDescription(BuildContext context, [String typePhrase = '']) {
    return switch (pubkeys.length) {
      1 => context.i18n.notifications_liked_one(typePhrase),
      2 => context.i18n.notifications_liked_two(typePhrase),
      _ => context.i18n.notifications_liked_many(total - 1, typePhrase),
    };
  }
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

  @override
  String getDescription(BuildContext context) {
    return switch (pubkeys.length) {
      1 => context.i18n.notifications_followed_one,
      2 => context.i18n.notifications_followed_two,
      _ => context.i18n.notifications_followed_many(total - 1)
    };
  }
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

  @override
  String getDescription(BuildContext context) {
    return switch (type) {
      ContentIonNotificationType.posts => context.i18n.notifications_posted_new_post,
      ContentIonNotificationType.stories => context.i18n.notifications_posted_new_story,
      ContentIonNotificationType.articles => context.i18n.notifications_posted_new_article,
      ContentIonNotificationType.videos => context.i18n.notifications_posted_new_video,
    };
  }
}

final class TokenLaunchIonNotification extends IonNotification {
  TokenLaunchIonNotification({
    required this.eventReference,
    required super.timestamp,
  }) : super(pubkeys: [eventReference.masterPubkey]);

  final EventReference eventReference;

  @override
  Widget getIcon(BuildContext context, {required double size}) => TokenNotificationIcon(size: size);

  @override
  String getDescription(BuildContext context, [IonConnectEntity? entity]) {
    return switch (entity) {
      ModifiablePostEntity() || PostEntity() => context.i18n.notifications_token_launched_post,
      ArticleEntity() => context.i18n.notifications_token_launched_article,
      UserMetadataEntity() => context.i18n.notifications_token_launched_creator,
      _ => ''
    };
  }
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

  @override
  String getDescription(
    BuildContext context, [
    IonConnectEntity? entity,
    bool isCurrentUserTokenTransaction = false,
  ]) {
    return switch (entity) {
      CommunityTokenActionEntity() => switch (entity.data.type) {
          CommunityTokenActionType.buy => switch (entity.data.kind) {
              ModifiablePostEntity.kind || PostEntity.kind => isCurrentUserTokenTransaction
                  ? context.i18n.notifications_token_transaction_buy_post
                  : context.i18n.notifications_token_transaction_buy_other_user_post,
              ArticleEntity.kind => isCurrentUserTokenTransaction
                  ? context.i18n.notifications_token_transaction_buy_article
                  : context.i18n.notifications_token_transaction_buy_other_user_article,
              UserMetadataEntity.kind => isCurrentUserTokenTransaction
                  ? context.i18n.notifications_token_transaction_buy_creator
                  : context.i18n.notifications_token_transaction_buy_other_user_creator,
              _ => '',
            },
          CommunityTokenActionType.sell => switch (entity.data.kind) {
              ModifiablePostEntity.kind || PostEntity.kind => isCurrentUserTokenTransaction
                  ? context.i18n.notifications_token_transaction_sell_post
                  : context.i18n.notifications_token_transaction_sell_other_user_post,
              ArticleEntity.kind => isCurrentUserTokenTransaction
                  ? context.i18n.notifications_token_transaction_sell_article
                  : context.i18n.notifications_token_transaction_sell_other_user_article,
              UserMetadataEntity.kind => isCurrentUserTokenTransaction
                  ? context.i18n.notifications_token_transaction_sell_creator
                  : context.i18n.notifications_token_transaction_sell_other_user_creator,
              _ => '',
            }
        },
      _ => ''
    };
  }
}
