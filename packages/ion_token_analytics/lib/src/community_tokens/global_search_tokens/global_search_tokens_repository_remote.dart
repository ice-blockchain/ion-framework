// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/category_tokens/models/models.dart';
import 'package:ion_token_analytics/src/community_tokens/global_search_tokens/global_search_tokens_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/models.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class GlobalSearchTokensRepositoryRemote implements GlobalSearchTokensRepository {
  GlobalSearchTokensRepositoryRemote(this._client);

  final NetworkClient _client;

  @override
  Future<PaginatedCategoryTokensData> searchCommunityTokens({
    required List<String> externalAddresses,
    String? keyword,
    int? includeTopPlatformHolders,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _client.get<List<dynamic>>(
      '/v1/community-tokens/',
      queryParameters: {
        'externalAddresses': externalAddresses,
        'limit': limit,
        'offset': offset,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        if (includeTopPlatformHolders != null)
          'includeTopPlatformHolders': includeTopPlatformHolders,
      },
    );

    final items = response.map((e) => CommunityToken.fromJson(e as Map<String, dynamic>)).toList();
    final hasMore = items.length == limit;
    final nextOffset = offset + items.length;

    return PaginatedCategoryTokensData(items: items, nextOffset: nextOffset, hasMore: hasMore);
  }
}
