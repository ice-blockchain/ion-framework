// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/category_tokens/category_tokens_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/category_tokens/data_sources/category_tokens_data_source_mock.dart';
import 'package:ion_token_analytics/src/community_tokens/category_tokens/models/models.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/models.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

// MOCK REPOSITORY: Handles category tokens (Trending/Top) with viewing sessions.
// Uses CategoryTokensDataSourceMock to get raw JSON, then parses it with fromJson().
class CategoryTokensRepositoryMock implements CategoryTokensRepository {
  CategoryTokensRepositoryMock() : _dataSource = CategoryTokensDataSourceMock();

  final CategoryTokensDataSourceMock _dataSource;

  @override
  Future<ViewingSession> createViewingSession(TokenCategoryType type) async {
    final json = await _dataSource.createViewingSession(type.value);
    return ViewingSession.fromJson(json);
  }

  @override
  Future<PaginatedCategoryTokensData> getCategoryTokens({
    required String sessionId,
    required TokenCategoryType type,
    String? keyword,
    int limit = 20,
    int offset = 0,
  }) async {
    final jsonList = await _dataSource.getCategoryTokens(
      sessionId: sessionId,
      type: type.value,
      keyword: keyword,
      limit: limit,
      offset: offset,
    );

    final items = jsonList.map(CommunityToken.fromJson).toList();
    final hasMore = jsonList.length == limit;
    final nextOffset = offset + jsonList.length;

    return PaginatedCategoryTokensData(items: items, nextOffset: nextOffset, hasMore: hasMore);
  }

  @override
  Future<NetworkSubscription<CommunityTokenPatch>> subscribeToRealtimeUpdates({
    required String sessionId,
    required TokenCategoryType type,
  }) async {
    final jsonStream = _dataSource.subscribeToRealtimeUpdates(
      sessionId: sessionId,
      type: type.value,
    );

    final patchStream = jsonStream.map((json) {
      return CommunityTokenPatch.fromJson(json);
    });

    return NetworkSubscription<CommunityTokenPatch>(
      stream: patchStream,
      close: () async {
        _dataSource.close();
      },
    );
  }
}
