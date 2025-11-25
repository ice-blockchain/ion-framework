// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/category_tokens/data_sources/category_tokens_data_source_mock.dart';
import 'package:ion_token_analytics/src/community_tokens/category_tokens/models/models.dart';
import 'package:ion_token_analytics/src/community_tokens/latest_tokens/latest_tokens_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/models.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class LatestTokensRepositoryMock implements LatestTokensRepository {
  LatestTokensRepositoryMock() : _dataSource = CategoryTokensDataSourceMock();

  final CategoryTokensDataSourceMock _dataSource;

  @override
  Future<PaginatedCategoryTokensData> getLatestTokens({
    String? keyword,
    String? type,
    int limit = 20,
    int offset = 0,
  }) async {
    final jsonList = await _dataSource.getLatestTokens(
      keyword: keyword,
      type: type,
      limit: limit,
      offset: offset,
    );

    final items = jsonList.map(CommunityToken.fromJson).toList();
    final hasMore = jsonList.length == limit;
    final nextOffset = offset + jsonList.length;

    return PaginatedCategoryTokensData(items: items, nextOffset: nextOffset, hasMore: hasMore);
  }

  @override
  Future<NetworkSubscription<CommunityTokenPatch>> subscribeToLatestTokens({
    String? keyword,
    String? type,
  }) async {
    final jsonStream = _dataSource.subscribeToLatestRealtimeUpdates(keyword: keyword, type: type);

    final patchStream = jsonStream.map((json) {
      try {
        return CommunityToken.fromJson(json);
      } catch (_) {
        return CommunityTokenPatch.fromJson(json);
      }
    });

    return NetworkSubscription<CommunityTokenPatch>(
      stream: patchStream,
      close: () async {
        _dataSource.close();
      },
    );
  }
}
