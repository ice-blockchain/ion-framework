// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_market_info_provider.r.g.dart';

@riverpod
Stream<CommunityToken?> tokenMarketInfo(Ref ref, String masterPubkey) async* {
  final client = await ref.watch(ionTokenAnalyticsClientProvider.future);

  // 1. Fetch initial data via REST
  final currentToken = (await client.communityTokens.getTokenInfo([masterPubkey]))
      //TODO: remove this when we integrate token info endpoint in BE
      // .where((token) => token.addresses.ionConnect == masterPubkey)
      .firstOrNull;
  yield currentToken;

  // 2. Subscribe to real-time updates
  final subscription = await client.communityTokens.subscribeToTokenInfo([masterPubkey]);

  try {
    await for (final patch in subscription.stream) {
      //TODO: remove this when we integrate token info endpoint in BE
      // if (patch.addresses?.ionConnect == masterPubkey) {
      if (currentToken == null) {
        yield patch as CommunityToken;
      } else {
        final patchedToken = currentToken.merge(patch);
        yield patchedToken;
      }
    }
  } catch (e, stackTrace) {
    print(e);
    print(stackTrace);
    yield null;
  } finally {
    await subscription.close();
  }
}
