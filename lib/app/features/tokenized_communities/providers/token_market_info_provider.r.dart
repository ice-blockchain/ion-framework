// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_action_first_buy_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/constants.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/sentry/sentry_service.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_market_info_provider.r.g.dart';

@riverpod
class TokenMarketInfo extends _$TokenMarketInfo {
  StreamSubscription<CommunityTokenBase>? _streamSubscription;
  NetworkSubscription<CommunityTokenBase>? _networkSubscription;
  CommunityToken? _activeTokenState;
  bool _disposed = false;

  @override
  Stream<CommunityToken?> build(String externalAddress) async* {
    _disposed = false;
    _streamSubscription = null;
    _networkSubscription = null;

    ref.onDispose(() {
      Logger.log('[TokenMarketInfo] Disposing for $externalAddress');
      _disposed = true;
      _streamSubscription?.cancel();
      _networkSubscription?.close();
    });

    final cachedtoken = ref.read(cachedTokenMarketInfoNotifierProvider(externalAddress));

    if (cachedtoken != null) {
      yield cachedtoken;
    }

    final client = await ref.watch(ionTokenAnalyticsClientProvider.future);

    final currentToken = await client.communityTokens.getTokenInfo(externalAddress);

    if (currentToken == null) {
      unawaited(_subscribeSse(client, externalAddress, null));
      yield null;
    } else {
      final adjusted = _processAndCacheToken(currentToken, ref);
      if (adjusted != null) {
        yield adjusted;
      }
    }

    unawaited(_subscribeSse(client, externalAddress, currentToken));
  }

  Future<void> _subscribeSse(
    IonTokenAnalyticsClient client,
    String externalAddress,
    CommunityToken? initialToken,
  ) async {
    _activeTokenState = initialToken;
    try {
      final subscription = await client.communityTokens.subscribeToTokenInfo(externalAddress);
      if (subscription == null || _disposed) {
        await subscription?.close();
        return;
      }

      _networkSubscription = subscription;
      _streamSubscription = subscription.stream.listen(
        (update) {
          if (update is CommunityToken) {
            _activeTokenState = update;
          } else if (update is CommunityTokenPatch && _activeTokenState != null) {
            _activeTokenState = _activeTokenState!.merge(update);
          } else {
            return;
          }

          final adjusted = _processAndCacheToken(_activeTokenState!, ref);
          if (adjusted != null) {
            state = AsyncData(adjusted);
          }
        },
        onError: (Object e, StackTrace stackTrace) {
          unawaited(SentryService.logException(e, stackTrace: stackTrace));
          Logger.error(e, stackTrace: stackTrace, message: '[TokenMarketInfo] Stream error');
        },
      );
    } catch (e, stackTrace) {
      unawaited(SentryService.logException(e, stackTrace: stackTrace));
      Logger.error(e, stackTrace: stackTrace, message: '[TokenMarketInfo] Failed to subscribe');
    }
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
  BigInt? _expectedPositionWei;

  @override
  CommunityToken? build(String externalAddress) {
    keepAliveWhenAuthenticated(ref);
    return null;
  }

  CommunityToken cacheToken(CommunityToken token) {
    final adjustedToken = _applyExpectedPosition(token);
    if (state != adjustedToken) {
      state = adjustedToken;
    }
    return adjustedToken;
  }

  void adjustPositionAfterSell(double soldAmount) {
    final currentToken = state;
    if (currentToken == null) return;

    final currentPosition = currentToken.marketData.position;
    if (currentPosition == null) return;

    final currentAmountWei = BigInt.tryParse(currentPosition.amount) ?? BigInt.zero;
    final soldAmountWei =
        BigInt.from(soldAmount * TokenizedCommunitiesConstants.weiPerToken.toDouble());
    final newAmountWei = currentAmountWei - soldAmountWei;
    final clampedAmountWei = newAmountWei.isNegative ? BigInt.zero : newAmountWei;

    _expectedPositionWei = clampedAmountWei;
    final newAmountValue = clampedAmountWei / TokenizedCommunitiesConstants.weiPerToken;

    final priceUSD = currentToken.marketData.priceUSD;
    final newAmountUSD = newAmountValue * priceUSD;

    final adjustedPosition = currentPosition.copyWith(
      amount: clampedAmountWei.toString(),
      amountUSD: newAmountUSD,
    );

    final adjustedMarketData = currentToken.marketData.copyWith(
      position: adjustedPosition,
    );

    state = currentToken.copyWith(marketData: adjustedMarketData);
  }

  void clearPendingAdjustment() {
    _expectedPositionWei = null;
  }

  CommunityToken _applyExpectedPosition(CommunityToken token) {
    if (_expectedPositionWei == null) {
      return token;
    }

    final currentPosition = token.marketData.position;
    if (currentPosition == null) return token;

    final incomingAmountWei = BigInt.tryParse(currentPosition.amount) ?? BigInt.zero;

    if (incomingAmountWei <= _expectedPositionWei!) {
      _expectedPositionWei = null;
      return token;
    }

    final priceUSD = token.marketData.priceUSD;
    final expectedAmountValue = _expectedPositionWei! / TokenizedCommunitiesConstants.weiPerToken;
    final newAmountUSD = expectedAmountValue * priceUSD;

    final adjustedPosition = currentPosition.copyWith(
      amount: _expectedPositionWei!.toString(),
      amountUSD: newAmountUSD,
    );

    final adjustedMarketData = token.marketData.copyWith(
      position: adjustedPosition,
    );

    return token.copyWith(marketData: adjustedMarketData);
  }
}

CommunityToken? _processAndCacheToken(CommunityToken token, Ref ref) {
  if (!token.isMarketValid) {
    unawaited(SentryService.logException(TokenMarketDataNotValidException(token)));
    return null;
  }

  return ref
      .read(cachedTokenMarketInfoNotifierProvider(token.externalAddress).notifier)
      .cacheToken(token);
}

extension on CommunityToken {
  bool get isMarketValid => marketData.priceUSD > 0 && marketData.marketCap > 0;
}
