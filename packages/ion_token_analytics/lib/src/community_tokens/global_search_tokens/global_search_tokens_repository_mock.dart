// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/category_tokens/data_sources/category_tokens_data_source_mock.dart';
import 'package:ion_token_analytics/src/community_tokens/category_tokens/models/models.dart';
import 'package:ion_token_analytics/src/community_tokens/global_search_tokens/global_search_tokens_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/models.dart';

class GlobalSearchTokensRepositoryMock implements GlobalSearchTokensRepository {
  GlobalSearchTokensRepositoryMock() : _dataSource = CategoryTokensDataSourceMock();

  final CategoryTokensDataSourceMock _dataSource;

  @override
  Future<PaginatedCategoryTokensData> searchCommunityTokens({
    required List<String> externalAddresses,
    String? keyword,
    int? includeTopPlatformHolders,
    int limit = 20,
    int offset = 0,
  }) async {
    // Mock ignores externalAddresses/includeTopPlatformHolders; uses existing mock data.
    final jsonList = await _dataSource.getLatestTokens(
      keyword: keyword,
      limit: limit,
      offset: offset,
    );

    final items = jsonList.map(CommunityToken.fromJson).toList();
    final hasMore = jsonList.length == limit;
    final nextOffset = offset + jsonList.length;

    return PaginatedCategoryTokensData(items: items, nextOffset: nextOffset, hasMore: hasMore);
  }
}
