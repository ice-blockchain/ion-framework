// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/features/user/model/tab_type_interface.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

enum CreatorTokensTabType implements TabType {
  trending,
  top,
  latest;

  @override
  String get iconAsset {
    return switch (this) {
      CreatorTokensTabType.trending => Assets.svg.iconMemeTranding,
      CreatorTokensTabType.top => Assets.svg.iconChannelType,
      CreatorTokensTabType.latest => Assets.svg.iconFieldCalendar,
    };
  }

  @override
  String getTitle(BuildContext context) {
    switch (this) {
      case CreatorTokensTabType.trending:
        return context.i18n.feed_advanced_search_category_trending;
      case CreatorTokensTabType.top:
        return context.i18n.feed_advanced_search_category_top;
      case CreatorTokensTabType.latest:
        return context.i18n.feed_advanced_search_category_latest;
    }
  }

  String getContentPageTitle(BuildContext context) {
    switch (this) {
      case CreatorTokensTabType.trending:
        return context.i18n.tokenized_communities_trending_tokens;
      case CreatorTokensTabType.top:
        return context.i18n.tokenized_communities_top_tokens;
      case CreatorTokensTabType.latest:
        return context.i18n.feed_advanced_search_category_latest;
    }
  }
}

extension CreatorTokensTabTypeX on CreatorTokensTabType {
  bool get isLatest => this == CreatorTokensTabType.latest;

  TokenCategoryType? get categoryType => switch (this) {
        CreatorTokensTabType.trending => TokenCategoryType.trending,
        CreatorTokensTabType.top => TokenCategoryType.top,
        CreatorTokensTabType.latest => null,
      };
}
