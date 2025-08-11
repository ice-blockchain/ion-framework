// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_provider.r.g.dart';

const List<Duration> _defaultRetryDelays = <Duration>[
  Duration(milliseconds: 200),
  Duration(milliseconds: 400),
  Duration(milliseconds: 600),
  Duration(milliseconds: 800),
  Duration(seconds: 1),
  Duration(seconds: 2),
  Duration(seconds: 3),
  Duration(seconds: 4),
  Duration(seconds: 5),
];

@riverpod
Dio dio(Ref ref) => _configureDefaultDioInterceptors(Dio());

@riverpod
Dio dioHttp2(Ref ref) => _configureDefaultDioInterceptors(
      Dio()
        ..httpClientAdapter = Http2Adapter(
          ConnectionManager(),
        ),
    );

Dio _configureDefaultDioInterceptors(
  Dio dio, {
  List<Duration> retryDelays = _defaultRetryDelays,
}) {
  final logger = Logger.talkerDioLogger;

  if (logger != null) {
    dio.interceptors.add(logger);
  }

  dio.interceptors.add(
    RetryInterceptor(
      dio: dio,
      retries: retryDelays.length,
      retryDelays: retryDelays,
    ),
  );

  return dio;
}
