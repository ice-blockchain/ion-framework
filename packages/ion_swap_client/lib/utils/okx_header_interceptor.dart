// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class OkxHeaderInterceptor implements Interceptor {
  OkxHeaderInterceptor({
    required this.apiKey,
    required this.signKey,
    required this.passphrase,
    required this.baseUrl,
  });

  final String apiKey;
  final String signKey;
  final String passphrase;
  final String baseUrl;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final dateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
    final timestamp = dateFormat.format(DateTime.now().toUtc());

    options.headers['OK-ACCESS-KEY'] = apiKey;
    options.headers['OK-ACCESS-TIMESTAMP'] = timestamp;
    options.headers['OK-ACCESS-PASSPHRASE'] = passphrase;

    // Prepare method
    final method = switch (options.method.toUpperCase()) {
      'POST' => _RequestMethod.postRequest,
      _ => _RequestMethod.getRequest,
    };

    // Prepare request path (include query string if present)
    // Dio stores either a relative path or a full URL in `options.path`.
    // We normalize to just the path component, preserving the query string.
    final fullUrl = options.baseUrl + options.path;
    final pathToReplace = _getBaseUrl(
      fullUrl,
    );
    final requestPath = fullUrl.replaceFirst(pathToReplace, '/');
    final requestPathWithQueryParams = _normalizeRequestPath(
      requestPath,
      options.queryParameters,
    );

    // Prepare body (empty for GET or when no payload)
    final body = () {
      final data = options.data;
      if (data == null) return '';
      if (data is String) return data;
      return jsonEncode(data);
    }();

    options.headers['OK-ACCESS-SIGN'] = await _generateSign(
      timestamp: timestamp,
      method: method,
      path: requestPathWithQueryParams,
      body: body,
      secretKey: signKey,
    );

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }

  @override
  // ignore: strict_raw_type
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  Future<String> _generateSign({
    required String timestamp,
    required _RequestMethod method,
    required String path,
    required String body,
    required String secretKey,
  }) async {
    final signString = '$timestamp${method.value}$path$body';
    final message = utf8.encode(signString);
    final keyBytes = utf8.encode(secretKey);
    final macAlgorithm = Hmac.sha256();

    final mac = await macAlgorithm.calculateMac(
      message,
      secretKey: SecretKey(keyBytes),
    );
    return base64Encode(mac.bytes);
  }

  String _getBaseUrl(String url) {
    final parts = url.split('/');
    return '${parts[0]}//${parts[2]}/';
  }

  String _normalizeRequestPath(String path, Map<String, dynamic> queryParameters) {
    if (queryParameters.isEmpty) {
      return path;
    }

    final queryString = queryParameters.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value.toString())}',
        )
        .join('&');

    return '$path?$queryString';
  }
}

enum _RequestMethod {
  getRequest,
  postRequest;

  String get value => switch (this) {
        _RequestMethod.getRequest => 'GET',
        _RequestMethod.postRequest => 'POST',
      };
}
