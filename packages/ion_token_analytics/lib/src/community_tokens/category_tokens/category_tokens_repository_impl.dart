// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/category_tokens/category_tokens_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/category_tokens/models/models.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/models.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class CategoryTokensRepositoryImpl implements CategoryTokensRepository {
  CategoryTokensRepositoryImpl(this._client);

  final NetworkClient _client;

  @override
  Future<ViewingSession> createViewingSession(TokenCategoryType type) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/v1/community-tokens/${type.value}/viewing-sessions',
    );
    return ViewingSession.fromJson(response);
  }

  @override
  Future<PaginatedCategoryTokensData> getCategoryTokens({
    required String sessionId,
    required TokenCategoryType type,
    String? keyword,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _client.get<List<dynamic>>(
      '/v1/community-tokens/${type.value}/viewing-sessions/$sessionId',
      queryParameters: {
        'limit': limit,
        'offset': offset,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      },
    );

    final items = response.map((e) => CommunityToken.fromJson(e as Map<String, dynamic>)).toList();
    final hasMore = items.length == limit;
    final nextOffset = offset + items.length;

    return PaginatedCategoryTokensData(items: items, nextOffset: nextOffset, hasMore: hasMore);
  }

  @override
  Future<NetworkSubscription<List<CommunityTokenBase>>> subscribeToRealtimeUpdates({
    required String sessionId,
    required TokenCategoryType type,
  }) async {
    final subscription = await _client.subscribeSse<Map<String, dynamic>>(
      '/v1sse/community-tokens/${type.value}',
      queryParameters: {'viewingSessionId': sessionId},
    );

    final stream = subscription.stream.map<CommunityTokenBase>((data) {
      try {
        return CommunityToken.fromJson(data);
      } catch (_) {
        return CommunityTokenPatch.fromJson(data);
      }
    });

    // TODO: migrate later to use stream of tokens, not list of tokens
    final listStream = stream.map((token) => [token]);
    return NetworkSubscription<List<CommunityTokenBase>>(
      stream: listStream,
      close: subscription.close,
    );
  }
}
