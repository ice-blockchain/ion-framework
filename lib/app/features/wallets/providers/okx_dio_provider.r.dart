// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ion/app/features/core/providers/dio_provider.r.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'okx_dio_provider.r.g.dart';

@Riverpod(keepAlive: true)
Dio okxDio(Ref ref) {
  final dio = Dio();
  final env = ref.watch(envProvider.notifier);

  final logger = Logger.talkerDioLogger!;
  logger.settings = logger.settings.copyWith(
    errorFilter: (exception) {
      final status = exception.response?.statusCode;
      if (status == 404) {
        return false;
      }
      return true;
    },
  );
  dio.interceptors.add(logger);
  dio.interceptors.add(
    _OkxHeaderInterceptor(
      apiKey: env.get<String>(EnvVariable.OKX_API_KEY),
      signKey: env.get<String>(EnvVariable.OKX_SIGN_KEY),
      passphrase: env.get<String>(EnvVariable.OKX_PASSPHRASE),
    ),
  );

  final retry = configureDioRetryInterceptor(dio);
  dio.interceptors.add(retry);

  return dio;
}

class _OkxHeaderInterceptor implements Interceptor {
  _OkxHeaderInterceptor({
    required this.apiKey,
    required this.signKey,
    required this.passphrase,
  });

  final String apiKey;
  final String signKey;
  final String passphrase;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
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
    final requestUri = () {
      final raw = options.path;
      return raw.startsWith('http') ? Uri.parse(raw) : Uri.parse(options.uri.toString());
    }();
    final requestPath = requestUri.hasQuery ? '${requestUri.path}?${requestUri.query}' : requestUri.path;

    // Prepare body (empty for GET or when no payload)
    final body = () {
      final data = options.data;
      if (data == null) return '';
      if (data is String) return data;
      return jsonEncode(data);
    }();

    options.headers['OK-ACCESS-SIGN'] = _generateSign(
      timestamp: timestamp,
      method: method,
      path: requestPath,
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

  String _generateSign({
    required String timestamp,
    required _RequestMethod method,
    required String path,
    required String body,
    required String secretKey,
  }) {
    final signString = '$timestamp${method.value}$path$body';
    final message = utf8.encode(signString);
    final keyBytes = utf8.encode(secretKey);
    final macAlgorithm = Hmac.sha256().toSync();

    final mac = macAlgorithm.calculateMacSync(
      message,
      secretKeyData: SecretKeyData(keyBytes),
      nonce: const <int>[],
    );
    return base64Encode(mac.bytes);
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
