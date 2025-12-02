// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';

class AuthHeaderInterceptor implements Interceptor {
  AuthHeaderInterceptor({
    required this.apiKey,
    required this.isBearer,
  });

  final String apiKey;
  final bool isBearer;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Authorization'] = isBearer ? 'Bearer $apiKey' : apiKey;

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
}
