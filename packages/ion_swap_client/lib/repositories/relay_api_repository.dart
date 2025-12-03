// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:ion_swap_client/models/relay_chain.m.dart';
import 'package:ion_swap_client/models/relay_quote.m.dart';

class RelayApiRepository {
  RelayApiRepository({
    required Dio dio,
  }) : _dio = dio;
  final Dio _dio;

  Future<List<RelayChain>> getChains() async {
    final response = await _dio.get<dynamic>(
      '/chains',
    );
    final data = response.data as Map<String, dynamic>;
    final chains = data['chains'] as List<dynamic>;
    return chains.map((e) => RelayChain.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RelayQuote> getQuote({
    required String user,
    required int originChainId,
    required int destinationChainId,
    required String originCurrency,
    required String destinationCurrency,
    required String amount,
    required String recipient,
  }) async {
    final response = await _dio.post<dynamic>(
      '/quote',
      data: {
        'tradeType': 'EXACT_INPUT',
        'user': user,
        'originChainId': originChainId,
        'destinationChainId': destinationChainId,
        'originCurrency': originCurrency,
        'destinationCurrency': destinationCurrency,
        'amount': amount,
        'recipient': recipient,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return RelayQuote.fromJson(data);
  }
}
