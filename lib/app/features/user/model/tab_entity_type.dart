// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

enum TabEntityType {
  posts,
  replies,
  holdings,
  videos,
  articles;

  String getEmptyStateTitleForCurrentUser(BuildContext context) {
    final locale = context.i18n;
    return switch (this) {
      TabEntityType.posts => locale.profile_posts_empty_list_current_user,
      TabEntityType.replies => locale.profile_replies_empty_list_current_user,
      TabEntityType.holdings => locale.profile_holdings_empty_list_current_user,
      TabEntityType.videos => locale.profile_videos_empty_list_current_user,
      TabEntityType.articles => locale.profile_articles_empty_list_current_user,
    };
  }

  String getEmptyStateTitle(BuildContext context, String username) {
    final locale = context.i18n;
    return switch (this) {
      TabEntityType.posts => locale.profile_posts_empty_list(username),
      TabEntityType.replies => locale.profile_replies_empty_list(username),
      TabEntityType.holdings => locale.profile_holdings_empty_list(username),
      TabEntityType.videos => locale.profile_videos_empty_list(username),
      TabEntityType.articles => locale.profile_articles_empty_list(username),
    };
  }

  String get emptyStateIconAsset => switch (this) {
        TabEntityType.posts => Assets.svg.walletIconProfileEmptyposts,
        TabEntityType.replies => Assets.svg.walletIconProfileEmptyreplies,
        TabEntityType.holdings => Assets.svg.walletIconProfileEmptyholdings,
        TabEntityType.videos => Assets.svg.walletIconProfileEmptyvideo,
        TabEntityType.articles => Assets.svg.walletIconProfileEmptyarticles,
      };
}
