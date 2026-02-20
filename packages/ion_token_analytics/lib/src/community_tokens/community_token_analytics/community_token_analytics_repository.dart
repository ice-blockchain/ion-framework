// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/token_info/models/community_token_analytics_response.f.dart';

/// Repository for global community token analytics (not tied to a specific token).
///
/// GET /v1/community-token-analytics/{analyticsType}?interval={interval}
abstract class CommunityTokenAnalyticsRepository {
  Future<CommunityTokenAnalyticsResponse?> getCommunityTokenAnalytics({
    required String analyticsType,
    required String interval,
  });
}
