// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/tokenized_communities/domain/trade_community_token_service.dart';
import 'package:ion/app/features/tokenized_communities/enums/community_token_trade_mode.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/wallets/utils/crypto_amount_converter.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class TradeCommunityTokenQuoteRequest {
  TradeCommunityTokenQuoteRequest({
    required this.externalAddress,
    required this.externalAddressType,
    required this.mode,
    required this.amount,
    required this.amountDecimals,
  });

  final String externalAddress;
  final ExternalAddressType externalAddressType;
  final CommunityTokenTradeMode mode;

  /// User-entered amount in human units.
  final double amount;

  /// Decimals used to convert [amount] to blockchain units.
  final int amountDecimals;
}

typedef TradeCommunityTokenServiceResolver = Future<TradeCommunityTokenService> Function();

/// A quote lifecycle controller.
///
/// - Debounces quote requests.
/// - Ensures only the latest request updates the consumer.
/// - Polls sequentially without overlapping requests.
/// - Does not depend on Riverpod.
class TradeCommunityTokenQuoteController {
  TradeCommunityTokenQuoteController({
    required TradeCommunityTokenServiceResolver serviceResolver,
    required Duration debounce,
  })  : _serviceResolver = serviceResolver,
        _debounce = debounce;

  final TradeCommunityTokenServiceResolver _serviceResolver;
  final Duration _debounce;

  Timer? _debounceTimer;
  int _requestId = 0;
  int? _inFlightRequestId;

  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _requestId++;
  }

  void cancel() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _requestId++;
  }

  void schedule({
    required TradeCommunityTokenQuoteRequest? request,
    required void Function() onReset,
    required void Function() onStart,
    required void Function(PricingResponse pricing) onSuccess,
    required void Function(Object error, StackTrace stackTrace) onError,
    bool enablePolling = true,
    Duration pollInterval = const Duration(milliseconds: 500),
    void Function()? onPollStart,
    void Function(Object error, StackTrace stackTrace)? onPollError,
  }) {
    _debounceTimer?.cancel();

    if (request == null || request.amount <= 0) {
      _requestId++;
      onReset();
      return;
    }

    final currentRequestId = ++_requestId;

    _debounceTimer = Timer(_debounce, () async {
      await _runOnce(
        currentRequestId: currentRequestId,
        request: request,
        onStart: onStart,
        onSuccess: onSuccess,
        onError: onError,
      );

      if (!enablePolling) return;

      unawaited(
        _pollLoop(
          currentRequestId: currentRequestId,
          request: request,
          pollInterval: pollInterval,
          onStart: onPollStart,
          onSuccess: onSuccess,
          onError: onPollError ?? onError,
        ),
      );
    });
  }

  Future<void> _pollLoop({
    required int currentRequestId,
    required TradeCommunityTokenQuoteRequest request,
    required Duration pollInterval,
    required void Function()? onStart,
    required void Function(PricingResponse pricing) onSuccess,
    required void Function(Object error, StackTrace stackTrace) onError,
  }) async {
    while (currentRequestId == _requestId) {
      await Future<void>.delayed(pollInterval);
      if (currentRequestId != _requestId) return;

      await _runOnce(
        currentRequestId: currentRequestId,
        request: request,
        onStart: onStart,
        onSuccess: onSuccess,
        onError: onError,
      );
    }
  }

  Future<void> _runOnce({
    required int currentRequestId,
    required TradeCommunityTokenQuoteRequest request,
    required void Function()? onStart,
    required void Function(PricingResponse pricing) onSuccess,
    required void Function(Object error, StackTrace stackTrace) onError,
  }) async {
    if (currentRequestId != _requestId) return;
    if (_inFlightRequestId == currentRequestId) return;

    _inFlightRequestId = currentRequestId;
    try {
      if (currentRequestId != _requestId) return;

      onStart?.call();

      final service = await _serviceResolver();

      final apiAmount = toBlockchainUnits(request.amount, request.amountDecimals).toString();

      final pricing = await service.getQuote(
        externalAddress: request.externalAddress,
        externalAddressType: request.externalAddressType,
        mode: request.mode,
        amount: apiAmount,
      );

      if (currentRequestId != _requestId) return;
      onSuccess(pricing);
    } catch (e, stackTrace) {
      if (currentRequestId != _requestId) return;
      onError(e, stackTrace);
    } finally {
      if (_inFlightRequestId == currentRequestId) {
        _inFlightRequestId = null;
      }
    }
  }
}
