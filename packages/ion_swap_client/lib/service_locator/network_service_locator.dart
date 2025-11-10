import 'package:dio/dio.dart';
import 'package:ion_swap_client/ion_swap_config.dart';
import 'package:ion_swap_client/utils/okx_header_interceptor.dart';

class NetworkServiceLocator with _OkxDio, _RelayDio {
  factory NetworkServiceLocator() {
    return _instance;
  }

  NetworkServiceLocator._internal();

  static final NetworkServiceLocator _instance = NetworkServiceLocator._internal();
}

mixin _OkxDio {
  Dio? _okxDioInstance;

  Dio okxDio({
    required IONSwapConfig config,
  }) {
    if (_okxDioInstance != null) {
      return _okxDioInstance!;
    }
    final dio = Dio(
      BaseOptions(
        baseUrl: config.okxApiUrl,
      ),
    );
    dio.interceptors.addAll(config.interceptors);

    dio.interceptors.add(
      OkxHeaderInterceptor(
        apiKey: config.okxApiKey,
        signKey: config.okxSignKey,
        passphrase: config.okxPassphrase,
        baseUrl: config.okxApiUrl,
      ),
    );

    _okxDioInstance = dio;
    return dio;
  }
}

mixin _RelayDio {
  Dio? _relayDioInstance;

  Dio relayDio({
    required IONSwapConfig config,
  }) {
    if (_relayDioInstance != null) {
      return _relayDioInstance!;
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: config.relayBaseUrl,
      ),
    );
    dio.interceptors.addAll(config.interceptors);

    _relayDioInstance = dio;
    return dio;
  }
}
