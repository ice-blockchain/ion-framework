import 'package:ion_token_analytics/src/http2_client/http2_client.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_request_options.dart';

class NetworkClient {
  NetworkClient.fromBaseUrl(String baseUrl) : _client = Http2Client.fromBaseUrl(baseUrl);

  final Http2Client _client;

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
      headers: headers,
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
      headers: headers,
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
      options: Http2RequestOptions(method: method, timeout: _defaultTimeout, headers: headers),
    );

    if (response.statusCode != 200) {
      throw Exception('Request failed with status ${response.statusCode}: $path');
    }

    return response.data as T;
  }

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

  Future<NetworkSubscription<T>> subscribe<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final subscription = await _client.subscribe<T>(
      path,
      queryParameters: _buildQueryParameters(queryParameters),
      headers: headers,
    );

    return NetworkSubscription<T>(stream: subscription.stream, close: subscription.close);
  }

  Future<void> dispose() {
    return _client.dispose();
  }
}

class NetworkSubscription<T> {
  NetworkSubscription({required this.stream, required this.close});
  final Stream<T> stream;
  final Future<void> Function() close;
}
