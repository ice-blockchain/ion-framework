// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/dio_provider.r.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swap_disabled_repository.r.g.dart';

class SwapDisabledRepository {
  SwapDisabledRepository({
    required Dio dio,
    required String url,
  })  : _dio = dio,
        _url = url;

  final Dio _dio;
  final String _url;

  Future<bool> isIonTrade() async {
    try {
      final response = await _dio.get<dynamic>(_url);
      final data = response.data as Map<String, dynamic>;
      return data['ionTrade'] == true;
    } catch (e) {
      return false;
    }
  }
}

@Riverpod(keepAlive: true)
Future<SwapDisabledRepository> swapDisabledRepository(Ref ref) async {
  final env = ref.read(envProvider.notifier);
  return SwapDisabledRepository(
    dio: ref.watch(dioProvider),
    url: env.get<String>(EnvVariable.CRYPTOCURRENCIES_ION_TRADE_URL),
  );
}
