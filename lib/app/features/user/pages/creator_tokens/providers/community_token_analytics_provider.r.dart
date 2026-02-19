// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_analytics_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/market_data_formatter.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/creator_tokens_analytics_sheet.dart';
import 'package:ion/app/utils/formatters.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_token_analytics_provider.r.g.dart';

/// Fetches community token analytics for the given [range] (24h, 7d, or 30d)
/// and maps to [CreatorTokensAnalyticsMetrics]. Only the requested interval
/// is fetched so the result returns as soon as possible.
@riverpod
Future<CreatorTokensAnalyticsMetrics> creatorTokensAnalyticsMetrics(
  Ref ref,
  CreatorTokensAnalyticsRange range,
) async {
  const analyticsType = 'global';
  final response = await ref.read(
    communityTokenAnalyticsProvider(
      (
        analyticsType: analyticsType,
        interval: range.label,
      ),
    ).future,
  );
  if (response == null) return const CreatorTokensAnalyticsMetrics();
  return CreatorTokensAnalyticsMetrics(
    tokensLaunched: formatCompactNumber(response.launched),
    migrated: formatCompactNumber(response.migrated),
    volume: MarketDataFormatter.formatPrice(response.volume),
  );
}
