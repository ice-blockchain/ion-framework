// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/category_tokens/models/models.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/models.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

abstract class CategoryTokensRepository {
  Future<ViewingSession> createViewingSession(TokenCategoryType type);

  Future<PaginatedCategoryTokensData> getCategoryTokens({
    required String sessionId,
    required TokenCategoryType type,
    String? keyword,
    int limit = 20,
    int offset = 0,
  });

  Future<NetworkSubscription<CommunityTokenBase>> subscribeToRealtimeUpdates({
    required String sessionId,
    required TokenCategoryType type,
  });
}
