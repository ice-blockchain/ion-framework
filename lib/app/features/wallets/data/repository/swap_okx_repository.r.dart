import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/wallets/data/models/swap_chain_data.m.dart';
import 'package:ion/app/features/wallets/data/models/swap_quote_response.m.dart';
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

  // TODO(ice-erebus): implement actual data
  Future<List<Map<String, int>>> getSupportedChainsIds() async {
    return [
      {'Avalanche': 43114},
      {'Arbitrum One': 42161},
      {'Optimism': 10},
      {'Polygon': 137},
      {'Solana': 501},
      {'Base': 8453},
      {'Ton': 607},
      {'Tron': 195},
      {'Ethereum': 1},
    ];
  }

  Future<List<SwapChainData>> getSupportedChains() async {
    final response = await _dio.get<dynamic>(
      '$_baseUrl/aggregator/supported/chain',
    );

    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;

    return data
        .map(
          (e) => SwapChainData.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> getTokens({
    required int chainIndex,
  }) async {
    await _dio.get<dynamic>(
      '$_baseUrl/aggregator/all-tokens',
      queryParameters: {
        'chainIndex': chainIndex,
      },
    );
  }

  Future<SwapQuoteResponse> getQuotes({
    required int chainIndex,
    required String amount,
    required String fromTokenAddress,
    required String toTokenAddress,
  }) async {
    final response = await _dio.get<dynamic>(
      '$_baseUrl/aggregator/quote',
      queryParameters: {
        'chainIndex': chainIndex,
        'amount': 1,
        'swapMode': 'exactIn',
        'fromTokenAddress': fromTokenAddress,
        'toTokenAddress': toTokenAddress,
      },
    );

    return SwapQuoteResponse.fromJson(
      response.data as Map<String, dynamic>,
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
