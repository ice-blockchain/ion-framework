// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:ion_swap_client/models/approve_transaction_data.m.dart';
import 'package:ion_swap_client/models/okx_api_response.m.dart';
import 'package:ion_swap_client/models/swap_chain_data.m.dart';
import 'package:ion_swap_client/models/swap_quote_data.m.dart';

class SwapOkxRepository {
  SwapOkxRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  String get _aggregatorBaseUrl => '/aggregator';

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
          (json as List<dynamic>?)
              ?.map((e) => ApproveTransactionData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Future<void> swap({
    required String chainIndex,
    required String amount,
    required String toTokenAddress,
    required String fromTokenAddress,
    required String userWalletAddress,
    String slippagePercent = '3',
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
        'slippagePercent': slippagePercent,
      },
    );
  }

  Future<void> broadcastSwap({
    required String chainIndex,
    required String address,
  }) async {
    await _dio.post<dynamic>(
      '/pre-transaction/broadcast-transaction',
      queryParameters: {
        'chainIndex': chainIndex,
        'address': address,
      },
    );
  }
}
