// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/community_token_analytics/community_token_analytics_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/community_token_analytics_response.f.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class CommunityTokenAnalyticsRepositoryImpl implements CommunityTokenAnalyticsRepository {
  CommunityTokenAnalyticsRepositoryImpl(this.client);

  final NetworkClient client;

  @override
  Future<CommunityTokenAnalyticsResponse?> getCommunityTokenAnalytics({
    required String analyticsType,
    required String interval,
  }) async {
    try {
      final responseData = await client.get<Map<String, dynamic>>(
        '/v1/community-token-analytics/$analyticsType',
        queryParameters: {'interval': interval},
      );
      return CommunityTokenAnalyticsResponse.fromJson(responseData);
    } catch (error, stackTrace) {
      client.logger?.error(
        'Failed to get community token analytics',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
