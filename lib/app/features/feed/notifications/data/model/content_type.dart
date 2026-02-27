// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/user/model/user_notifications_type.dart';

enum ContentType {
  posts(0),
  stories(1),
  articles(2),
  videos(3),
  tokenizedCommunitiesTransactions(4);

  const ContentType(this.value);

  factory ContentType.fromUserNotificationType(UserNotificationsType notificationType) {
    return switch (notificationType) {
      UserNotificationsType.posts => ContentType.posts,
      UserNotificationsType.stories => ContentType.stories,
      UserNotificationsType.articles => ContentType.articles,
      UserNotificationsType.videos => ContentType.videos,
      UserNotificationsType.tokenizedCommunitiesTransactions =>
        ContentType.tokenizedCommunitiesTransactions,
      UserNotificationsType.none => throw ArgumentError('Invalid UserNotificationsType: none'),
    };
  }

  final int value;

  static ContentType fromValue(int value) {
    return ContentType.values.firstWhere((type) => type.value == value);
  }
}
