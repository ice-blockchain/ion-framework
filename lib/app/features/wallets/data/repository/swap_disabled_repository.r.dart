// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/dio_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swap_disabled_repository.r.g.dart';

class SwapDisabledRepository {
  SwapDisabledRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  static const _url = 'https://media.ice.io/ion/iontrade.json';

  Future<bool> isIonTrade() async {
    final response = await _dio.get<dynamic>(_url);
    final data = response.data as Map<String, dynamic>;
    return data['ionTrade'] == true;
  }
}

@Riverpod(keepAlive: true)
Future<SwapDisabledRepository> swapDisabledRepository(Ref ref) async {
  return SwapDisabledRepository(
    dio: ref.watch(dioProvider),
  );
}
