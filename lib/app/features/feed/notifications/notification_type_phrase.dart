// SPDX-License-Identifier: ice License 1.0

import 'package:ion/generated/app_localizations.dart';

/// Event type for notification description (matches entity resolution in notification_info).
enum NotificationEventType {
  post,
  comment,
  story,
  article,
}

/// Context in which the type phrase is used (determines case/possessive in some locales).
enum NotificationTypeContext {
  liked,
  replyToYour,
  replyToThe,
  repost,
  share,
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
    (NotificationTypeContext.share, NotificationEventType.post) =>
        l10n.notifications_type_your_post_share,
    (NotificationTypeContext.share, NotificationEventType.comment) =>
        l10n.notifications_type_your_comment_share,
    (NotificationTypeContext.share, NotificationEventType.story) =>
        l10n.notifications_type_your_story_share,
    (NotificationTypeContext.share, NotificationEventType.article) =>
        l10n.notifications_type_your_article_share,
    (NotificationTypeContext.shareThe, NotificationEventType.post) =>
        l10n.notifications_type_the_post_share,
    (NotificationTypeContext.shareThe, NotificationEventType.comment) =>
        l10n.notifications_type_the_comment_share,
    (NotificationTypeContext.shareThe, NotificationEventType.story) =>
        l10n.notifications_type_the_story_share,
    (NotificationTypeContext.shareThe, NotificationEventType.article) =>
        l10n.notifications_type_the_article_share,
  };
}
