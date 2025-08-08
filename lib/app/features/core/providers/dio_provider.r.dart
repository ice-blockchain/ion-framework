// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_provider.r.g.dart';

@riverpod
Dio dio(Ref ref) {
  final dio = Dio();

  final logger = Logger.talkerDioLogger;

  if (logger != null) {
    dio.interceptors.add(logger);
  }

  dio.interceptors.add(
    RetryInterceptor(
      dio: dio,
      retries: 9,
      retryDelays: const [
        Duration(milliseconds: 200),
        Duration(milliseconds: 400),
        Duration(milliseconds: 600),
        Duration(milliseconds: 800),
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 3),
        Duration(seconds: 4),
        Duration(seconds: 5),
      ],
    ),
  );

  return dio;
}
