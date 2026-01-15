// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

enum TokenTypeFilter {
  all,
  creator,
  content,
  x;

  String getLabel(BuildContext context) {
    return switch (this) {
      TokenTypeFilter.all => context.i18n.creator_tokens_filter_all_tokens,
      TokenTypeFilter.creator => context.i18n.creator_tokens_filter_creator_tokens,
      TokenTypeFilter.content => context.i18n.creator_tokens_filter_content_tokens,
      TokenTypeFilter.x => context.i18n.creator_tokens_filter_x_tokens,
    };
  }

  bool matchesTokenType(CommunityTokenType? tokenType, CommunityTokenSource tokenSource) {
    return switch (this) {
      TokenTypeFilter.all => true,
      TokenTypeFilter.creator => tokenType == CommunityTokenType.profile,
      TokenTypeFilter.content => tokenType != null &&
          tokenSource.isIonConnect &&
          (tokenType == CommunityTokenType.post ||
              tokenType == CommunityTokenType.video ||
              tokenType == CommunityTokenType.article),
      TokenTypeFilter.x => tokenSource == CommunityTokenSource.twitter,
    };
  }
}
