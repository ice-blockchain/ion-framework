// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:math' as math;

import 'package:ion_token_analytics/src/http2_client/http2_client.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_request_options.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_subscription.dart';

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

    if (response.statusCode != 200) {
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

    // Some SSE endpoints use a marker event with `Data: nil` (Go), which may be
    // delivered as a literal `<nil>` string. If the SSE decoder attempts to
    // `jsonDecode('<nil>')`, it throws a FormatException and would otherwise
    // terminate the stream.
    //
    // We intercept that error and convert it into an empty map event for
    // map-typed subscriptions. Downstream repositories can
    // interpret an empty map as the EOSE marker.
    //
    // Also handles automatic reconnection on connection errors during stream processing.
    final (stream, closeFn) = _createReconnectingStream<T>(
      subscription,
      path,
      queryParameters,
      headers,
    );

    return NetworkSubscription<T>(stream: stream, close: closeFn);
  }

  Future<void> dispose() {
    return _client.dispose();
  }

  /// Creates a reconnecting stream that automatically retries on connection errors.
  (Stream<T>, Future<void> Function()) _createReconnectingStream<T>(
      Http2Subscription<T> initialSubscription,
      String path,
      Map<String, dynamic>? queryParameters,
      Map<String, String>? headers,
      ) {
    final controller = StreamController<T>.broadcast();
    var currentSubscription = initialSubscription;
    StreamSubscription<T>? currentListener;
    var isClosed = false;
    var reconnectAttempts = 0;
    const maxRetryDelayMs = 10000; // 10 seconds max delay

    void listenToSubscription(Http2Subscription<T> sub) {
      // Cancel previous listener if exists
      currentListener?.cancel();

      currentListener = sub.stream.listen(
            (data) {
          if (!controller.isClosed && !isClosed) {
            controller.add(data);
            reconnectAttempts = 0; // Reset on successful data
          }
        },
        onError: (Object error, StackTrace stackTrace) async {
          if (controller.isClosed || isClosed) return;

          final text = error.toString();
          final isNil = error is FormatException && text.contains('<nil>');

          if (isNil) {
            // Handle <nil> marker
            if (<String, dynamic>{} is T) {
              controller.add(<String, dynamic>{} as T);
              return;
            }
            if (<dynamic, dynamic>{} is T) {
              controller.add(<dynamic, dynamic>{} as T);
              return;
            }
            return;
          }

          // Retry indefinitely with exponential backoff (capped at maxRetryDelayMs)
          reconnectAttempts++;
          try {
            // Close the old subscription
            try {
              await currentSubscription.close();
            } catch (_) {
              // Ignore errors closing old subscription
            }

            // Disconnect the dead connection
            try {
              await _client.connection.disconnect();
            } catch (_) {
              // Ignore errors during disconnect
            }

            // Wait before retrying using exponential backoff (capped at maxRetryDelayMs)
            final delayMs = math.min(
              maxRetryDelayMs,
              (200 * math.pow(2, reconnectAttempts - 1)).toInt(),
            );
            await Future<void>.delayed(Duration(milliseconds: delayMs));

            // Create a new subscription (bypassing the outer subscribeSse to avoid double retry)
            final newSub = await _client.subscribeSse<T>(
              path,
              queryParameters: _buildQueryParameters(queryParameters),
              headers: _addAuthorizationHeader(headers),
            );

            currentSubscription = newSub;

            // Listen to the new subscription
            listenToSubscription(newSub);
          } catch (reconnectError) {
            // Retry indefinitely - will trigger onError again and retry
            listenToSubscription(currentSubscription);
          }
        },
        onDone: () {
          if (!controller.isClosed && !isClosed) {
            controller.close();
          }
        },
        cancelOnError: false,
      );
    }

    // Start listening to the initial subscription
    listenToSubscription(initialSubscription);

    // Close function
    Future<void> closeFn() async {
      if (isClosed) return;
      isClosed = true;
      await currentListener?.cancel();
      try {
        await currentSubscription.close();
      } catch (_) {
        // Ignore errors
      }
      if (!controller.isClosed) {
        await controller.close();
      }
    }

    return (controller.stream, closeFn);
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
