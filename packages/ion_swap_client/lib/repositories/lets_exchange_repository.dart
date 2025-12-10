// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:ion_swap_client/models/lets_exchange_coin.m.dart';
import 'package:ion_swap_client/models/lets_exchange_info.m.dart';
import 'package:ion_swap_client/models/lets_exchange_transaction.m.dart';

class LetsExchangeRepository {
  LetsExchangeRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  Future<List<LetsExchangeCoin>> getCoins() async {
    final response = await _dio.get<dynamic>(
      '/v2/coins',
    );
    final data = response.data as List<dynamic>;

    return data.map((e) => LetsExchangeCoin.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<LetsExchangeInfo> getRates({
    required String from,
    required String to,
    required String networkFrom,
    required String networkTo,
    required String amount,
    required String affiliateId,
  }) async {
    final response = await _dio.post<dynamic>(
      '/v1/info',
      data: {
        'from': from,
        'to': to,
        'network_from': networkFrom,
        'network_to': networkTo,
        'amount': amount,
        'affiliate_id': affiliateId,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return LetsExchangeInfo.fromJson(data);
  }

  Future<LetsExchangeTransaction> createTransaction({
    required String coinFrom,
    required String coinTo,
    required String networkFrom,
    required String networkTo,
    required String depositAmount,
    required String withdrawalAddress,
    required String affiliateId,
    required String rateId,
    required String withdrawalExtraId,
  }) async {
    final response = await _dio.post<dynamic>(
      '/v1/transaction',
      data: {
        'coin_from': coinFrom,
        'coin_to': coinTo,
        'network_from': networkFrom,
        'network_to': networkTo,
        'deposit_amount': depositAmount,
        'affiliate_id': affiliateId,
        'withdrawal': withdrawalAddress,
        'rate_id': rateId,
        'withdrawal_extra_id': withdrawalExtraId,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return LetsExchangeTransaction.fromJson(data);
  }

  Future<void> getTransactionStatus({
    required String transactionId,
  }) async {
    await _dio.get<dynamic>(
      '/v1/transaction/$transactionId',
    );
  }
}
