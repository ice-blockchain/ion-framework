// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion/app/services/sentry/sentry_service.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bulk_token_market_info_prefetch_provider.r.g.dart';

/// Prefetches token market info for multiple external addresses in a single bulk
/// API call, populating the [CachedTokenMarketInfoNotifier] cache so that
/// individual [tokenMarketInfoProvider] instances can read from warm cache.
@riverpod
Future<void> bulkTokenMarketInfoPrefetch(
  Ref ref,
  List<String> externalAddresses,
) async {
  if (externalAddresses.isEmpty) return;

  // Filter out addresses that are already cached
  final uncachedAddresses = externalAddresses.where((addr) {
    final cached = ref.read(cachedTokenMarketInfoNotifierProvider(addr));
    return cached == null;
  }).toList();

  if (uncachedAddresses.isEmpty) return;

  try {
    final client = await ref.read(ionTokenAnalyticsClientProvider.future);
    final tokens = await client.communityTokens.getTokenInfoBulk(uncachedAddresses);

    for (final token in tokens) {
      if (token.marketData.priceUSD > 0 && token.marketData.marketCap > 0) {
        ref
            .read(cachedTokenMarketInfoNotifierProvider(token.externalAddress).notifier)
            .cacheToken(token);
      }
    }
  } catch (e, stackTrace) {
    unawaited(SentryService.logException(e, stackTrace: stackTrace));
  }
}
