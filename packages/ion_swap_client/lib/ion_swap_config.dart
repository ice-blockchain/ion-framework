// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';

class IONSwapConfig {
  IONSwapConfig({
    required this.okxApiKey,
    required this.okxSignKey,
    required this.okxPassphrase,
    required this.okxApiUrl,
    required this.relayBaseUrl,
    required this.exolixApiKey,
    required this.exolixApiUrl,
    required this.letsExchangeApiKey,
    required this.letsExchangeApiUrl,
    required this.letsExchangeAffiliateId,
    required this.ionSwapContractAddress,
    required this.iceBscTokenAddress,
    required this.ionBscTokenAddress,
    required this.ionBridgeRouterContractAddress,
    required this.ionBridgeContractAddress,
    this.interceptors = const [],
  });

  final String okxApiKey;
  final String okxSignKey;
  final String okxPassphrase;
  final String okxApiUrl;

  final String relayBaseUrl;

  final String exolixApiKey;
  final String exolixApiUrl;

  final String letsExchangeApiKey;
  final String letsExchangeApiUrl;
  final String letsExchangeAffiliateId;

  final String ionSwapContractAddress;
  final String ionBridgeRouterContractAddress;
  final String ionBridgeContractAddress;
  final String iceBscTokenAddress;
  final String ionBscTokenAddress;

  final List<Interceptor> interceptors;
}
