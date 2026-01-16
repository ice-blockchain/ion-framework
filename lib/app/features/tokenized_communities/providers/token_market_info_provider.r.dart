// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_action_first_buy_provider.r.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_market_info_provider.r.g.dart';

@riverpod
Stream<CommunityToken?> tokenMarketInfo(
  Ref ref,
  String externalAddress,
) async* {
  // Read cache once at startup (don't watch to avoid restarting stream on cache updates)
  final cachedToken = ref.read(cachedTokenMarketInfoNotifierProvider(externalAddress));

  if (cachedToken != null) {
    yield cachedToken;
  }

  final client = await ref.watch(ionTokenAnalyticsClientProvider.future);

  // 1. Fetch initial data via REST
  final currentToken = await client.communityTokens.getTokenInfo(externalAddress);

  if (currentToken != null) {
    unawaited(
      ref
          .read(cachedTokenMarketInfoNotifierProvider(externalAddress).notifier)
          .cacheToken(currentToken),
    );
  }

  yield currentToken ?? cachedToken;

  // 2. Subscribe to real-time updates
  final subscription = await client.communityTokens.subscribeToTokenInfo(externalAddress);

  try {
    if (subscription == null) {
      return;
    }

    var mutableToken = currentToken;
    await for (final patch in subscription.stream) {
      if (mutableToken == null) {
        mutableToken = patch as CommunityToken;
      } else {
        mutableToken = mutableToken.merge(patch);
      }
      unawaited(
        ref
            .read(cachedTokenMarketInfoNotifierProvider(externalAddress).notifier)
            .cacheToken(mutableToken),
      );
      yield mutableToken;
    }
  } catch (e) {
    return;
  } finally {
    await subscription?.close();
  }
}

// Guarded wrapper that checks if entity has a token before delegating to tokenMarketInfoProvider.
@riverpod
AsyncValue<CommunityToken?> tokenMarketInfoIfAvailable(
  Ref ref,
  EventReference eventReference,
) {
  final hasTokenAsync = ref.watch(
    ionConnectEntityHasTokenProvider(eventReference: eventReference),
  );
  final hasToken = hasTokenAsync.valueOrNull ?? false;

  if (!hasToken) {
    return const AsyncData(null);
  }

  return ref.watch(tokenMarketInfoProvider(eventReference.toString()));
}

@riverpod
class CachedTokenMarketInfoNotifier extends _$CachedTokenMarketInfoNotifier {
  @override
  CommunityToken? build(String externalAddress) {
    keepAliveWhenAuthenticated(ref);
    return null;
  }

  Future<void> cacheToken(CommunityToken token) async {
    state = token;
  }
}
