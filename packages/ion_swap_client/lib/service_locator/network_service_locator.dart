// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:ion_swap_client/ion_swap_config.dart';
import 'package:ion_swap_client/utils/auth_header_interceptor.dart';
import 'package:ion_swap_client/utils/okx_header_interceptor.dart';

class NetworkServiceLocator with _OkxDio, _RelayDio, _ExolixDio, _LetsExchangeDio {
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

mixin _LetsExchangeDio {
  Dio? _letsExchangeDioInstance;

  Dio letsExchangeDio({
    required IONSwapConfig config,
  }) {
    if (_letsExchangeDioInstance != null) {
      return _letsExchangeDioInstance!;
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: config.letsExchangeApiUrl,
      ),
    );
    dio.interceptors.addAll(config.interceptors);

    dio.interceptors.add(
      AuthHeaderInterceptor(
        apiKey: config.letsExchangeApiKey,
        isBearer: true,
      ),
    );

    _letsExchangeDioInstance = dio;
    return dio;
  }
}

mixin _ExolixDio {
  Dio? _exolixDioInstance;

  Dio exolixDio({
    required IONSwapConfig config,
  }) {
    if (_exolixDioInstance != null) {
      return _exolixDioInstance!;
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: config.exolixApiUrl,
      ),
    );
    dio.interceptors.addAll(config.interceptors);

    dio.interceptors.add(
      AuthHeaderInterceptor(
        apiKey: config.exolixApiKey,
        isBearer: false,
      ),
    );

    _exolixDioInstance = dio;
    return dio;
  }
}
