// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/category_tokens/category_tokens_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/category_tokens/data_sources/category_tokens_data_source_mock.dart';
import 'package:ion_token_analytics/src/community_tokens/category_tokens/models/models.dart';

// MOCK REPOSITORY: Creates viewing sessions for Trending/Top categories.
// Uses CategoryTokensDataSourceMock to get raw JSON
class CategoryTokensRepositoryMock implements CategoryTokensRepository {
  CategoryTokensRepositoryMock() : _dataSource = CategoryTokensDataSourceMock();

  final CategoryTokensDataSourceMock _dataSource;

  @override
  Future<ViewingSession> createViewingSession(TokenCategoryType type) async {
    final json = await _dataSource.createViewingSession(type.value);

    return ViewingSession.fromJson(json);
  }
}
