// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_analytics_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/market_data_formatter.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/creator_tokens_analytics_sheet.dart';
import 'package:ion/app/utils/formatters.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_token_analytics_provider.r.g.dart';

/// Fetches community token analytics for all intervals (24h, 7d, 30d) and maps
/// to [CreatorTokensAnalyticsMetrics] for the analytics sheet.
@riverpod
Future<Map<CreatorTokensAnalyticsRange, CreatorTokensAnalyticsMetrics>>
    creatorTokensAnalyticsMetrics(Ref ref) async {
  const analyticsType = 'global';

  final results = await Future.wait<
      ({CreatorTokensAnalyticsRange range, CreatorTokensAnalyticsMetrics? metrics})>(
    CreatorTokensAnalyticsRange.values.map((range) async {
      final response = await ref.read(
        communityTokenAnalyticsProvider(
          (
            analyticsType: analyticsType,
            interval: range.label,
          ),
        ).future,
      );
      final metrics = response != null
          ? CreatorTokensAnalyticsMetrics(
              tokensLaunched: formatCompactNumber(response.launched),
              migrated: formatCompactNumber(response.migrated),
              volume: MarketDataFormatter.formatPrice(response.volume),
            )
          : null;
      return (range: range, metrics: metrics);
    }),
  );

  return Map.fromEntries(
    results.map((e) => MapEntry(e.range, e.metrics ?? const CreatorTokensAnalyticsMetrics())),
  );
}
