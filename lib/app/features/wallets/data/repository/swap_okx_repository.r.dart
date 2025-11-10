// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/wallets/data/models/approve_transaction_data.m.dart';
import 'package:ion/app/features/wallets/data/models/okx_api_response.m.dart';
import 'package:ion/app/features/wallets/data/models/swap_chain_data.m.dart';
import 'package:ion/app/features/wallets/data/models/swap_quote_data.m.dart';
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

  String get _aggregatorBaseUrl => '$_baseUrl/aggregator';

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

  Future<OkxApiResponse<List<SwapChainData>>> getSupportedChains() async {
    final response = await _dio.get<dynamic>(
      '$_aggregatorBaseUrl/supported/chain',
    );

    return OkxApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) =>
          (json as List<dynamic>?)
              ?.map(
                (e) => SwapChainData.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Future<OkxApiResponse<List<SwapQuoteData>>> getQuotes({
    required int chainIndex,
    required String amount,
    required String fromTokenAddress,
    required String toTokenAddress,
  }) async {
    final response = await _dio.get<dynamic>(
      '$_aggregatorBaseUrl/quote',
      queryParameters: {
        'chainIndex': chainIndex,
        'amount': amount,
        'swapMode': 'exactIn',
        'fromTokenAddress': fromTokenAddress,
        'toTokenAddress': toTokenAddress,
      },
    );

    return OkxApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) =>
          (json as List<dynamic>?)
              ?.map(
                (e) => SwapQuoteData.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Future<OkxApiResponse<List<ApproveTransactionData>>> approveTransaction({
    required String chainIndex,
    required String tokenContractAddress,
    required String amount,
  }) async {
    final response = await _dio.get<dynamic>(
      '$_aggregatorBaseUrl/approve-transaction',
      queryParameters: {
        'chainIndex': chainIndex,
        'approveAmount': amount,
        'tokenContractAddress': tokenContractAddress,
      },
    );

    return OkxApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) =>
          (json as List<dynamic>?)?.map((e) => ApproveTransactionData.fromJson(e as Map<String, dynamic>)).toList() ??
          [],
    );
  }

  Future<void> swap({
    required String chainIndex,
    required String amount,
    required String toTokenAddress,
    required String fromTokenAddress,
    required String userWalletAddress,
  }) async {
    await _dio.get<dynamic>(
      '$_aggregatorBaseUrl/swap',
      queryParameters: {
        'chainIndex': chainIndex,
        'amount': amount,
        'swapMode': 'exactIn',
        'fromTokenAddress': fromTokenAddress,
        'toTokenAddress': toTokenAddress,
        'userWalletAddress': userWalletAddress,
        // TODO(ice-erebus): ask for this data
        'slippagePercent': '0.5',
      },
    );
  }

  Future<void> simulateSwap() async {
    await _dio.get<dynamic>(
      '$_baseUrl/pre-transaction/simulate',
      queryParameters: {
        'fromAddress': '',
        'toAddress': '',
        'chainIndex': '',
        'extJson': {
          'inputData': '',
        },
      },
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
