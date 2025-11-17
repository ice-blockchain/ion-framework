// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_market_info_provider.r.g.dart';

@riverpod
Stream<CommunityToken?> tokenMarketInfo(Ref ref, String masterPubkey) async* {
  final client = await ref.watch(ionTokenAnalyticsClientProvider.future);
  final subscription = await client.communityTokens.subscribeToTokenInfo([masterPubkey]);

  try {
    await for (final tokens in subscription.stream) {
      // The API returns a list, but we're subscribing to a single address
      // so we should get either 0 or 1 token
      if (tokens.isNotEmpty) {
        yield tokens.first;
      } else {
        yield null;
      }
    }
  } finally {
    await subscription.close();
  }
}
