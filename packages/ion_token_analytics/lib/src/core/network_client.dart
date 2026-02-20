// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion_token_analytics/src/core/extensions/http_status_code.dart';
import 'package:ion_token_analytics/src/core/logger.dart';
import 'package:ion_token_analytics/src/core/models/network_response.dart';
import 'package:ion_token_analytics/src/core/models/network_subscription.dart';
import 'package:ion_token_analytics/src/core/network_exceptions.dart';
import 'package:ion_token_analytics/src/core/reconnecting_sse.dart';
import 'package:ion_token_analytics/src/http2_client/http2_client.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_request_options.dart';

export 'package:ion_token_analytics/src/core/models/network_response.dart';
export 'package:ion_token_analytics/src/core/models/network_subscription.dart';

/// Thin HTTP client that adds auth headers, query-param handling,
/// status-code validation, and reconnecting-SSE wrapping on top of [Http2Client].
class NetworkClient {
  NetworkClient.fromBaseUrl(String baseUrl, {required String? authToken, AnalyticsLogger? logger})
    : _client = Http2Client.fromBaseUrl(baseUrl, logger: logger),
      _authToken = authToken,
      _logger = logger;

  final Http2Client _client;
  final String? _authToken;
  final AnalyticsLogger? _logger;

  AnalyticsLogger? get logger => _logger;

  static const Duration _defaultTimeout = Duration(seconds: 30);

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _request<T>(
      path,
      queryParameters: _buildQueryParameters(queryParameters),
      method: 'GET',
      headers: _addAuthorizationHeader(headers),
    );
  }

  Future<NetworkResponse<T>> getWithResponse<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final response = await _client.request<T>(
      path,
      queryParameters: _buildQueryParameters(queryParameters),
      options: Http2RequestOptions(
        timeout: _defaultTimeout,
        headers: _addAuthorizationHeader(headers),
      ),
    );

    final statusCode = response.statusCode ?? 0;
    if (!statusCode.isSuccessStatusCode) {
      throw HttpStatusException(statusCode: statusCode, path: path);
    }

    return NetworkResponse<T>(data: response.data as T, headers: response.headers);
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _request<T>(
      path,
      data: data,
      queryParameters: _buildQueryParameters(queryParameters),
      method: 'POST',
      headers: _addAuthorizationHeader(headers),
    );
  }

  Future<T> _request<T>(
    String path, {
    required String method,
    Object? data,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final response = await _client.request<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Http2RequestOptions(
        method: method,
        timeout: _defaultTimeout,
        headers: _addAuthorizationHeader(headers),
      ),
    );

    final statusCode = response.statusCode ?? 0;
    if (!statusCode.isSuccessStatusCode) {
      throw HttpStatusException(statusCode: statusCode, path: path);
    }

    return response.data as T;
  }

  Future<NetworkSubscription<T>> subscribe<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final subscription = await _client.subscribe<T>(
      path,
      queryParameters: _buildQueryParameters(queryParameters),
      headers: _addAuthorizationHeader(headers),
    );

    return NetworkSubscription<T>(stream: subscription.stream, close: subscription.close);
  }

  Future<NetworkSubscription<T>> subscribeSse<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final queryParams = _buildQueryParameters(queryParameters);
    final fullPath = Uri(path: path, queryParameters: queryParams).toString();

    final initialSubscription = await _client.subscribeSse<T>(
      path,
      queryParameters: queryParams,
      headers: _addAuthorizationHeader(headers),
    );
    _logger?.log(
      '[NetworkClient] Opening initial SSE subscription: $path with query: $queryParams',
    );

    final reconnectingSse = ReconnectingSse<T>(
      initialSubscription: initialSubscription,
      createSubscription: () => _client.subscribeSse<T>(
        path,
        queryParameters: queryParams,
        headers: _addAuthorizationHeader(headers),
      ),
      path: fullPath,
      logger: _logger,
      onStaleConnection: _client.forceDisconnect,
    );

    return NetworkSubscription<T>(stream: reconnectingSse.stream, close: reconnectingSse.close);
  }

  Future<void> dispose() {
    return _client.dispose();
  }

  Future<void> forceDisconnect() {
    return _client.forceDisconnect();
  }

  Map<String, String> _buildQueryParameters(Map<String, dynamic>? queryParameters) {
    if (queryParameters == null) return {};

    final result = <String, String>{};
    for (final entry in queryParameters.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is List) {
        result['$key[]'] = value.join(',');
      } else {
        result[key] = value.toString();
      }
    }
    return result;
  }

  Map<String, String> _addAuthorizationHeader(Map<String, String>? headers) {
    final reqHeaders = headers ?? {};
    if (_authToken != null) {
      reqHeaders['Authorization'] = 'Nostr $_authToken';
    }
    return reqHeaders;
  }
}
