// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion/app/services/sentry/sentry_service.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bulk_token_market_info_prefetch_provider.r.g.dart';

/// Parameters for [bulkTokenMarketInfoPrefetch] with stable equality and hashCode.
@immutable
class BulkTokenMarketInfoPrefetchParams {
  BulkTokenMarketInfoPrefetchParams(List<String> externalAddresses)
      : externalAddresses = List.unmodifiable(externalAddresses);
  final List<String> externalAddresses;
  static const ListEquality<String> _equality = ListEquality<String>();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BulkTokenMarketInfoPrefetchParams &&
        _equality.equals(externalAddresses, other.externalAddresses);
  }

  @override
  int get hashCode => _equality.hash(externalAddresses);
}

/// Prefetches token market info for multiple external addresses in a single bulk
/// API call, populating the [CachedTokenMarketInfoNotifier] cache so that
/// individual [tokenMarketInfoProvider] instances can read from warm cache.
@riverpod
Future<void> bulkTokenMarketInfoPrefetch(
  Ref ref,
  BulkTokenMarketInfoPrefetchParams params,
) async {
  final externalAddresses = params.externalAddresses;
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
