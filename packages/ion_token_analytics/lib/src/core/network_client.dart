// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion_token_analytics/src/core/extensions/http_status_code.dart';
import 'package:ion_token_analytics/src/core/logger.dart';
import 'package:ion_token_analytics/src/core/reconnecting_sse.dart';
import 'package:ion_token_analytics/src/http2_client/http2_client.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_request_options.dart';

class NetworkClient {
  NetworkClient.fromBaseUrl(String baseUrl, {required String? authToken, AnalyticsLogger? logger})
    : _client = Http2Client.fromBaseUrl(baseUrl),
      _authToken = authToken,
      _logger = logger;

  final Http2Client _client;

  final String? _authToken;

  final AnalyticsLogger? _logger;

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
      //TODO: add custom exceptions with codes
      throw Exception('Request failed with status ${response.statusCode}: $path');
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
      //TODO: add custom exceptions with codes
      throw Exception('Request failed with status ${response.statusCode}: $path');
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
    final initialSubscription = await _client.subscribeSse<T>(
      path,
      queryParameters: _buildQueryParameters(queryParameters),
      headers: _addAuthorizationHeader(headers),
    );
    _logger?.log('[NetworkClient] Opening initial SSE subscription: $path');

    // Some SSE endpoints use a marker event with `Data: nil` (Go), which may be
    // delivered as a literal `<nil>` string. If the SSE decoder attempts to
    // `jsonDecode('<nil>')`, it throws a FormatException and would otherwise
    // terminate the stream.
    //
    // We intercept that error and convert it into an empty map event for
    // map-typed subscriptions. Downstream repositories can
    // interpret an empty map as the EOSE marker.
    //
    // Also handles automatic reconnection on connection errors during stream processing,
    // including stale connection detection (e.g., "Bad file descriptor" after app backgrounding).
    final reconnectingSse = ReconnectingSse<T>(
      initialSubscription: initialSubscription,
      createSubscription: () => _client.subscribeSse<T>(
        path,
        queryParameters: _buildQueryParameters(queryParameters),
        headers: _addAuthorizationHeader(headers),
      ),
      path: path,
      logger: _logger,
      onStaleConnection: _client.forceDisconnect,
    );

    return NetworkSubscription<T>(stream: reconnectingSse.stream, close: reconnectingSse.close);
  }

  Future<void> dispose() {
    return _client.dispose();
  }

  /// Forces the underlying HTTP/2 client to drop the current connection.
  ///
  /// Use this when the connection is suspected to be stale (e.g., after
  /// backgrounding) to ensure the next request/subscription reconnects.
  Future<void> forceDisconnect() {
    return _client.forceDisconnect();
  }

  /// Builds a map of query parameters suitable for HTTP requests.
  ///
  /// Converts the input [queryParameters] map into a string-based map where:
  /// - List values are joined with commas and the key is suffixed with '[]'
  /// - All other values are converted to strings using [toString()]
  ///
  /// Example:
  /// ```dart
  /// _buildQueryParameters({
  ///   'id': 123,
  ///   'tags': ['dart', 'flutter'],
  ///   'active': true
  /// })
  /// // Returns: {'id': '123', 'tags[]': 'dart,flutter', 'active': 'true'}
  /// ```
  Map<String, String> _buildQueryParameters(Map<String, dynamic>? queryParameters) {
    if (queryParameters == null) {
      return {};
    }

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

class NetworkResponse<T> {
  NetworkResponse({required this.data, this.headers});

  final T data;
  final Map<String, String>? headers;
}

class NetworkSubscription<T> {
  NetworkSubscription({required this.stream, required this.close});

  final Stream<T> stream;
  final Future<void> Function() close;
}
