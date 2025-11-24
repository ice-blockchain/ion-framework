// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:ion_token_analytics/src/community_tokens/featured_tokens/data_sources/featured_tokens_data_source_mock.dart';
import 'package:ion_token_analytics/src/community_tokens/featured_tokens/featured_tokens_repository.dart';

// MOCK REPOSITORY: Streams a list of featured CommunityTokens with periodic updates.
// Uses FeaturedTokensDataSourceMock to get raw JSON, then parses it with fromJson().
class FeaturedTokensRepositoryMock implements FeaturedTokensRepository {
  FeaturedTokensRepositoryMock() : _dataSource = FeaturedTokensDataSourceMock();

  final FeaturedTokensDataSourceMock _dataSource;

  @override
  Future<NetworkSubscription<List<CommunityToken>>> subscribeToFeaturedTokens() async {
    final featuredTokensSubscription = _dataSource.subscribeToFeaturedTokens();
    final tokenStream = featuredTokensSubscription.map(
      (jsonList) => jsonList.map(CommunityToken.fromJson).toList(),
    );

    return NetworkSubscription<List<CommunityToken>>(
      stream: tokenStream,
      close: () async {
        _dataSource.close();
      },
    );
  }
}
