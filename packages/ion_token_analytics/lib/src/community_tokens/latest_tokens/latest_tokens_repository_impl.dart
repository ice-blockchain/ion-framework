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
      '/v1/community-tokens/latest',
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
  Future<NetworkSubscription<List<CommunityTokenBase>>> subscribeToLatestTokens({
    String? keyword,
    String? type,
  }) async {
    final subscription = await _client.subscribeSse<List<dynamic>>(
      '/v1sse/community-tokens/latest',
      queryParameters: {
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        if (type != null) 'type': type,
      },
    );

    final stream = subscription.stream.map<List<CommunityTokenBase>>((jsons) {
      final items = <CommunityTokenBase>[];
      for (final json in jsons) {
        try {
          items.add(CommunityToken.fromJson(json as Map<String, dynamic>));
        } catch (_) {
          items.add(CommunityTokenPatch.fromJson(json as Map<String, dynamic>));
        }
      }
      return items;
    });

    return NetworkSubscription<List<CommunityTokenBase>>(stream: stream, close: subscription.close);
  }
}
