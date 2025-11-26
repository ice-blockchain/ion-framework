// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:ion_swap_client/models/exolix_coin.m.dart';
import 'package:ion_swap_client/models/exolix_rate.m.dart';
import 'package:ion_swap_client/models/exolix_transaction.m.dart';
import 'package:ion_swap_client/repositories/api_repository.dart';

class ExolixRepository implements ApiRepository {
  ExolixRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  Future<List<ExolixCoin>> getCoins({
    required String coinCode,
  }) async {
    final response = await _dio.get<dynamic>(
      '/currencies',
      queryParameters: {
        'withNetworks': true,
        'search': coinCode,
      },
    );
    final data = response.data['data'] as List<dynamic>;
    return data.map((json) => ExolixCoin.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<ExolixRate> getRates({
    required String coinFrom,
    required String networkFrom,
    required String coinTo,
    required String networkTo,
    required String amount,
  }) async {
    final response = await _dio.get<dynamic>(
      '/rate',
      queryParameters: {
        'rateType': 'fixed',
        'coinFrom': coinFrom,
        'networkFrom': networkFrom,
        'coinTo': coinTo,
        'networkTo': networkTo,
        'amount': amount,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return ExolixRate.fromJson(data);
  }

  Future<ExolixTransaction> createTransaction({
    required String coinFrom,
    required String networkFrom,
    required String coinTo,
    required String networkTo,
    required String amount,
    required String withdrawalAddress,
    required String? withdrawalExtraId,
  }) async {
    final response = await _dio.post<dynamic>(
      '/transactions',
      data: {
        'rateType': 'fixed',
        'coinFrom': coinFrom,
        'networkFrom': networkFrom,
        'coinTo': coinTo,
        'networkTo': networkTo,
        'amount': amount,
        'withdrawalAddress': withdrawalAddress,
        if (withdrawalExtraId != null) 'withdrawalExtraId': withdrawalExtraId,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return ExolixTransaction.fromJson(data);
  }
}
