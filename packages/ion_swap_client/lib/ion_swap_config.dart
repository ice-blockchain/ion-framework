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

  final List<Interceptor> interceptors;
}
