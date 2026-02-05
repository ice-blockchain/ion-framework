// SPDX-License-Identifier: ice License 1.0

enum PushNotificationCategory {
  /// Notifications from the accounts that the user configured to receive content from.
  posts,

  /// Notifications about the content that mentions the user.
  mentionsAndReplies,

  /// Notifications about reposts of the user's content.
  reposts,

  /// Notifications about new likes on the user's content.
  likes,

  /// Notifications about new followers.
  newFollowers,

  /// Notifications about new chat messages.
  directMessages,

  /// Not implemented.
  groupChats,

  /// Not implemented.
  channels,

  /// Notifications about payment requests.
  messagePaymentRequest,

  /// Notifications about received payments from within (encrypted) and outside (unencrypted) of the app.
  messagePaymentReceived,

  /// Not implemented.
  updates,

  /// Notifications about new tokens, created for the followed users.
  creatorToken,

  /// Notifications about new tokens, created for the content of the followed users.
  contentToken,

  /// Notifications about new trades for the user creator token.
  creatorTokenTrades,

  /// Notifications about new trades for the user content tokens.
  contentTokenTrades,

  /// Notifications about recommended tokens.
  tokenUpdates,
}
