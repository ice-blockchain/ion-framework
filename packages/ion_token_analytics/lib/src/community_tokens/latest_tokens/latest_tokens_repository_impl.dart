// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/category_tokens/models/models.dart';
import 'package:ion_token_analytics/src/community_tokens/latest_tokens/latest_tokens_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/models.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class LatestTokensRepositoryImpl implements LatestTokensRepository {
  LatestTokensRepositoryImpl(this._client);

  final NetworkClient _client;

  @override
  Future<PaginatedCategoryTokensData> getLatestTokens({
    String? keyword,
    String? type,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _client.get<List<dynamic>>(
      '/community-tokens/latest',
      queryParameters: {
        'limit': limit,
        'offset': offset,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        if (type != null) 'type': type,
      },
    );

    final items = response.map((e) => CommunityToken.fromJson(e as Map<String, dynamic>)).toList();
    final hasMore = items.length == limit;
    final nextOffset = offset + items.length;

    return PaginatedCategoryTokensData(items: items, nextOffset: nextOffset, hasMore: hasMore);
  }

  @override
  Future<NetworkSubscription<CommunityTokenBase>> subscribeToLatestTokens({
    String? keyword,
    String? type,
  }) async {
    final subscription = await _client.subscribe<Map<String, dynamic>>(
      '/community-tokens/latest',
      queryParameters: {
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        if (type != null) 'type': type,
      },
    );

    final stream = subscription.stream.map<CommunityTokenBase>((json) {
      try {
        return CommunityToken.fromJson(json);
      } catch (_) {
        return CommunityTokenPatch.fromJson(json);
      }
    });

    return NetworkSubscription<CommunityTokenBase>(stream: stream, close: subscription.close);
  }
}
