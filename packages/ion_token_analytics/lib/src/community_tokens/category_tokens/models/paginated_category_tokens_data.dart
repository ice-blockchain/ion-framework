// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/token_info/models/models.dart';

class PaginatedCategoryTokensData {
  const PaginatedCategoryTokensData({
    required this.items,
    required this.nextOffset,
    required this.hasMore,
  });

  final List<CommunityToken> items;
  final int nextOffset;
  final bool hasMore;
}
