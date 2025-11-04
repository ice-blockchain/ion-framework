import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/wallets/providers/okx_dio_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swap_okx_repository.r.g.dart';

class SwapOkxRepository {
  SwapOkxRepository({
    required Dio dio,
    required String baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String _baseUrl;

  Future<void> getSupportedChains() async {
    // TODO(ice-erebus): implement swap coins

    await _dio.get<dynamic>(
      '$_baseUrl/aggregator/supported/chain',
    );
  }
}

@Riverpod(keepAlive: true)
Future<SwapOkxRepository> swapOkxRepository(Ref ref) async {
  final env = ref.watch(envProvider.notifier);

  final dio = ref.watch(okxDioProvider);
  final baseUrl = env.get<String>(EnvVariable.OKX_API_URL);

  return SwapOkxRepository(
    dio: dio,
    baseUrl: baseUrl,
  );
}
