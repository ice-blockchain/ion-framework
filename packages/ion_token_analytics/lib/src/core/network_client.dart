// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/http2_client/http2_client.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_request_options.dart';

class NetworkClient {
  NetworkClient.fromBaseUrl(String baseUrl, {required String? authToken})
    : _client = Http2Client.fromBaseUrl(baseUrl),
      _authToken = authToken;

  final Http2Client _client;

  final String? _authToken;

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

    if (response.statusCode != 200) {
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
    final subscription = await _client.subscribeSse<T>(
      path,
      queryParameters: _buildQueryParameters(queryParameters),
      headers: _addAuthorizationHeader(headers),
    );

    return NetworkSubscription<T>(stream: subscription.stream, close: subscription.close);
  }

  Future<void> dispose() {
    return _client.dispose();
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

class NetworkSubscription<T> {
  NetworkSubscription({required this.stream, required this.close});
  final Stream<T> stream;
  final Future<void> Function() close;
}
