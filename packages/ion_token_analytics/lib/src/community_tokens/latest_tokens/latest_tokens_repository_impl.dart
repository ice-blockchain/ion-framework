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
    final subscription = await _client.subscribeSse<Map<String, dynamic>>(
      '/v1sse/community-tokens/latest',
      queryParameters: {
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        if (type != null) 'type': type,
      },
    );

    final stream = subscription.stream.map<List<CommunityTokenBase>>((data) {
      final list = <CommunityTokenBase>[];
      try {
        final token = CommunityToken.fromJson(data);
        list.add(token);
      } catch (_) {
        final patch = CommunityTokenPatch.fromJson(data);
        list.add(patch);
      }
      return list;
    });

    return NetworkSubscription<List<CommunityTokenBase>>(stream: stream, close: subscription.close);
  }
}
