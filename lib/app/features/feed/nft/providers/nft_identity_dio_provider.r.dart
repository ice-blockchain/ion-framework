// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/dio_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nft_identity_dio_provider.r.g.dart';

@Riverpod(keepAlive: true)
Dio nftIdentityDio(Ref ref) {
  final dio = Dio();

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

  final retry = configureDioRetryInterceptor(dio);
  dio.interceptors.add(retry);

  return dio;
}
