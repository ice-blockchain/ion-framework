// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/category_tokens/models/models.dart';

abstract class GlobalSearchTokensRepository {
  // Global search across community tokens.
  Future<PaginatedCategoryTokensData> searchCommunityTokens({
    required List<String> externalAddresses,
    String? keyword,
    int? includeTopPlatformHolders,
    int limit = 20,
    int offset = 0,
  });
}
