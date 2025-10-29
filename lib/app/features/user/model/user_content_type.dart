// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/features/user/model/tab_type_interface.dart';
import 'package:ion/generated/assets.gen.dart';

enum UserContentType implements TabType {
  posts,
  replies,
  videos,
  articles;

  @override
  String get iconAsset {
    return switch (this) {
      UserContentType.posts => Assets.svg.iconProfileFeed,
      UserContentType.replies => Assets.svg.iconFeedReplies,
      UserContentType.videos => Assets.svg.iconFeedVideos,
      UserContentType.articles => Assets.svg.iconFeedArticles,
    };
  }

  @override
  String getTitle(BuildContext context) {
    switch (this) {
      case UserContentType.posts:
        return context.i18n.profile_posts;
      case UserContentType.replies:
        return context.i18n.profile_replies;
      case UserContentType.videos:
        return context.i18n.profile_videos;
      case UserContentType.articles:
        return context.i18n.profile_articles;
    }
  }
}
