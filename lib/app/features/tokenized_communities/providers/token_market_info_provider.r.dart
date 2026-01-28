// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_action_first_buy_provider.r.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion/app/services/sentry/sentry_service.dart';
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
  if (_isValidToken(cachedToken, ref)) {
    yield cachedToken;
  }

  final client = await ref.watch(ionTokenAnalyticsClientProvider.future);

  // 1. Fetch initial data via REST
  final currentToken = await client.communityTokens.getTokenInfo(externalAddress);

  if (_isValidToken(currentToken, ref)) {
    yield currentToken;
  }

  // 2. Subscribe to real-time updates
  final subscription = await client.communityTokens.subscribeToTokenInfo(externalAddress);

  if (subscription == null) return;

  var activeTokenState = currentToken;

  try {
    await for (final update in subscription.stream) {
      if (update is CommunityToken) {
        activeTokenState = update;
      } else if (update is CommunityTokenPatch && activeTokenState != null) {
        activeTokenState = activeTokenState.merge(update);
      } else {
        continue;
      }

      if (_isValidToken(activeTokenState, ref)) {
        yield activeTokenState;
      }
    }
  } catch (e, stackTrace) {
    unawaited(SentryService.logException(e, stackTrace: stackTrace));
  } finally {
    await subscription.close();
  }
}

@riverpod
AsyncValue<CommunityToken?> tokenMarketInfoIfAvailable(
  Ref ref,
  EventReference eventReference,
) {
  final hasToken = ref.watch(
    ionConnectEntityHasTokenProvider(eventReference: eventReference)
        .select((value) => value.valueOrNull ?? false),
  );

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
    // Equality check to prevent redundant state updates
    if (state != token) {
      state = token;
    }
  }
}

bool _isValidToken(CommunityToken? token, Ref ref) {
  if (token == null) return false;

  if (!token.isMarketValid) {
    unawaited(SentryService.logException(TokenMarketDataNotValidException(token)));
    return false;
  }

  unawaited(
    ref
        .read(cachedTokenMarketInfoNotifierProvider(token.externalAddress).notifier)
        .cacheToken(token),
  );
  return true;
}

extension on CommunityToken {
  bool get isMarketValid => marketData.priceUSD > 0 && marketData.marketCap > 0;
}
