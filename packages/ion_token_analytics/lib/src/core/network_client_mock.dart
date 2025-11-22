// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion_token_analytics/src/community_tokens/latest_trades/mocks/latest_trades_mock_handler.dart';
import 'package:ion_token_analytics/src/community_tokens/top_holders/mocks/top_holders_mock_handler.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

/// A mock NetworkClient that intercepts specific requests and returns mock data.
class NetworkClientMock extends NetworkClient {
  NetworkClientMock(super.baseUrl) : super.fromBaseUrl();

  final _topHoldersHandler = TopHoldersMockHandler();
  final _latestTradesHandler = LatestTradesMockHandler();

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    if (path.contains('/latest-trades')) {
      final limit = queryParameters?['limit'] as int? ?? 10;
      return _latestTradesHandler.handleGet<T>(limit);
    }
    return super.get<T>(path, queryParameters: queryParameters, headers: headers);
  }

  @override
  Future<NetworkSubscription<T>> subscribe<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    // Intercept Top Holders subscription
    if (path.contains('/top-holders')) {
      final limit = queryParameters?['limit'] as int? ?? 6;
      return _topHoldersHandler.handleSubscription<T>(limit);
    }

    // Intercept Latest Trades subscription
    if (path.contains('/latest-trades')) {
      return _latestTradesHandler.handleSubscription<T>();
    }

    // Fallback to real implementation (or throw if strictly mock)
    return super.subscribe<T>(path, queryParameters: queryParameters, headers: headers);
  }
}
