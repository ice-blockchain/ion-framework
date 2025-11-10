import 'package:dio/dio.dart';

class IONSwapConfig {
  IONSwapConfig({
    required this.okxApiKey,
    required this.okxSignKey,
    required this.okxPassphrase,
    required this.okxApiUrl,
    required this.relayBaseUrl,
    this.interceptors = const [],
  });

  final String okxApiKey;
  final String okxSignKey;
  final String okxPassphrase;
  final String okxApiUrl;
  final List<Interceptor> interceptors;
  final String relayBaseUrl;
}
