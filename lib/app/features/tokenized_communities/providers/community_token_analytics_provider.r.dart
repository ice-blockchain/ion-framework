// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_infrastructure_providers.r.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_token_analytics_provider.r.g.dart';

typedef CommunityTokenAnalyticsParams = ({
  String analyticsType,
  String interval,
});

/// Fetches community token analytics (launched, migrated, volume) for the given
/// [analyticsType] and [interval].
///
/// Same pattern as [suggestTokenCreationDetails]: takes params, gets API from
/// [tradeCommunityTokenApiProvider], returns [CommunityTokenAnalyticsResponse].
@riverpod
Future<CommunityTokenAnalyticsResponse?> communityTokenAnalytics(
  Ref ref,
  CommunityTokenAnalyticsParams params,
) async {
  final api = await ref.watch(tradeCommunityTokenApiProvider.future);
  return api.getCommunityTokenAnalytics(
    analyticsType: params.analyticsType,
    interval: params.interval,
  );
}
