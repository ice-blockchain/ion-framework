// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/generated/app_localizations.dart';

/// Event type for notification description (matches entity resolution in notification_info).
enum NotificationEventType {
  post,
  comment,
  story,
  article,
  trade,
  token;

  factory NotificationEventType.fromIonConnectEntity(IonConnectEntity? entity) {
    return switch (entity) {
      ModifiablePostEntity() when entity.isStory => NotificationEventType.story,
      ModifiablePostEntity(:final data) when data.parentEvent != null =>
        NotificationEventType.comment,
      ArticleEntity() => NotificationEventType.article,
      CommunityTokenActionEntity() => NotificationEventType.trade,
      CommunityTokenDefinitionEntity() => NotificationEventType.token,
      _ => NotificationEventType.post,
    };
  }
}

/// Context in which the type phrase is used (determines case/possessive in some locales).
enum NotificationTypeContext {
  liked,
  replyToYour,
  replyToThe,
  repost,
  shareYour,
  shareThe,
}

/// Returns the localized type phrase (correct case + "your" where needed) for the given
/// context and event type. Substitute the result for `{type}` in the notification template.
String getNotificationTypePhrase(
  I18n l10n,
  NotificationTypeContext context,
  NotificationEventType eventType,
) {
  // Key naming: "your" or "the" + type + context (liked, reply_to, repost, share).
  // We cannot reuse one string across contexts for case languages (e.g. RU: acc vs gen vs instr).
  return switch ((context, eventType)) {
    (NotificationTypeContext.liked, NotificationEventType.post) =>
      l10n.notifications_type_your_post_liked,
    (NotificationTypeContext.liked, NotificationEventType.comment) =>
      l10n.notifications_type_your_comment_liked,
    (NotificationTypeContext.liked, NotificationEventType.story) =>
      l10n.notifications_type_your_story_liked,
    (NotificationTypeContext.liked, NotificationEventType.article) =>
      l10n.notifications_type_your_article_liked,
    (NotificationTypeContext.replyToYour, NotificationEventType.post) =>
      l10n.notifications_type_your_post_reply_to,
    (NotificationTypeContext.replyToYour, NotificationEventType.comment) =>
      l10n.notifications_type_your_comment_reply_to,
    (NotificationTypeContext.replyToYour, NotificationEventType.story) =>
      l10n.notifications_type_your_story_reply_to,
    (NotificationTypeContext.replyToYour, NotificationEventType.article) =>
      l10n.notifications_type_your_article_reply_to,
    (NotificationTypeContext.replyToThe, NotificationEventType.post) =>
      l10n.notifications_type_the_post_reply_to,
    (NotificationTypeContext.replyToThe, NotificationEventType.comment) =>
      l10n.notifications_type_the_comment_reply_to,
    (NotificationTypeContext.replyToThe, NotificationEventType.story) =>
      l10n.notifications_type_the_story_reply_to,
    (NotificationTypeContext.replyToThe, NotificationEventType.article) =>
      l10n.notifications_type_the_article_reply_to,
    (NotificationTypeContext.repost, NotificationEventType.post) =>
      l10n.notifications_type_your_post_repost,
    (NotificationTypeContext.repost, NotificationEventType.comment) =>
      l10n.notifications_type_your_comment_repost,
    (NotificationTypeContext.repost, NotificationEventType.story) =>
      l10n.notifications_type_your_story_repost,
    (NotificationTypeContext.repost, NotificationEventType.article) =>
      l10n.notifications_type_your_article_repost,
    (NotificationTypeContext.shareYour, NotificationEventType.post) =>
      l10n.notifications_type_your_post_share,
    (NotificationTypeContext.shareYour, NotificationEventType.comment) =>
      l10n.notifications_type_your_comment_share,
    (NotificationTypeContext.shareYour, NotificationEventType.story) =>
      l10n.notifications_type_your_story_share,
    (NotificationTypeContext.shareYour, NotificationEventType.article) =>
      l10n.notifications_type_your_article_share,
    (NotificationTypeContext.shareThe, NotificationEventType.post) =>
      l10n.notifications_type_the_post_share,
    (NotificationTypeContext.shareThe, NotificationEventType.comment) =>
      l10n.notifications_type_the_comment_share,
    (NotificationTypeContext.shareThe, NotificationEventType.story) =>
      l10n.notifications_type_the_story_share,
    (NotificationTypeContext.shareThe, NotificationEventType.article) =>
      l10n.notifications_type_the_article_share,
    (NotificationTypeContext.liked, NotificationEventType.trade) =>
      l10n.notifications_type_your_post_liked,
    (NotificationTypeContext.liked, NotificationEventType.token) =>
      l10n.notifications_type_your_post_liked,
    // TODO: Handle this case.
    (NotificationTypeContext.replyToYour, NotificationEventType.trade) =>
      throw UnimplementedError(),
    // TODO: Handle this case.
    (NotificationTypeContext.replyToYour, NotificationEventType.token) =>
      throw UnimplementedError(),
    // TODO: Handle this case.
    (NotificationTypeContext.replyToThe, NotificationEventType.trade) => throw UnimplementedError(),
    // TODO: Handle this case.
    (NotificationTypeContext.replyToThe, NotificationEventType.token) => throw UnimplementedError(),
    // TODO: Handle this case.
    (NotificationTypeContext.repost, NotificationEventType.trade) => throw UnimplementedError(),
    // TODO: Handle this case.
    (NotificationTypeContext.repost, NotificationEventType.token) => throw UnimplementedError(),
    // TODO: Handle this case.
    (NotificationTypeContext.shareYour, NotificationEventType.trade) => throw UnimplementedError(),
    // TODO: Handle this case.
    (NotificationTypeContext.shareYour, NotificationEventType.token) => throw UnimplementedError(),
    // TODO: Handle this case.
    (NotificationTypeContext.shareThe, NotificationEventType.trade) => throw UnimplementedError(),
    // TODO: Handle this case.
    (NotificationTypeContext.shareThe, NotificationEventType.token) => throw UnimplementedError(),
  };
}
