// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/auth_interceptor.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/service_locator/ion_identity_clients/auth_client_service_locator.dart';
import 'package:ion_identity_client/src/core/storage/biometrics_state_storage.dart';
import 'package:ion_identity_client/src/core/storage/local_passkey_creds_state_storage.dart';
import 'package:ion_identity_client/src/core/storage/private_key_storage.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';

class NetworkServiceLocator
    with
        _Dio,
        _Interceptors,
        _TokenStorage,
        _PrivateKeyStorage,
        _BiometricsStateStorage,
        _LocalPasskeyCredsStateStorage,
        _NetworkClient {
  factory NetworkServiceLocator() {
    return _instance;
  }

  NetworkServiceLocator._internal();

  static final NetworkServiceLocator _instance = NetworkServiceLocator._internal();
}

mixin _Dio {
  Dio? _dioInstance;

  Dio dio({
    required IONIdentityConfig config,
  }) {
    if (_dioInstance != null) {
      return _dioInstance!;
    }

    _dioInstance = _defaultDio(config);

    final interceptors = NetworkServiceLocator().interceptors(
      dio: _dioInstance!,
      config: config,
    );
    _dioInstance!.interceptors.addAll(interceptors);

    return _dioInstance!;
  }

  Dio _defaultDio(IONIdentityConfig config) {
    final dioOptions = BaseOptions(
      baseUrl: config.origin,
      headers: {
        RequestHeaders.ionIdentityClientId: config.appId,
      },
    );
    final dio = Dio(dioOptions);

    return dio;
  }

  Dio _refreshTokenDio(
    IONIdentityConfig config,
  ) {
    final dioOptions = BaseOptions(
      baseUrl: config.origin,
      headers: {
        RequestHeaders.ionIdentityClientId: config.appId,
      },
    );
    final dio = Dio(dioOptions);

    final interceptors = config.interceptors ?? [];
    dio.interceptors.addAll(interceptors);

    return dio;
  }
}

mixin _Interceptors {
  List<Interceptor> interceptors({
    required Dio dio,
    required IONIdentityConfig config,
  }) {
    final extraInterceptors = config.interceptors ?? [];
    return <Interceptor>[
      ...extraInterceptors,
      authInterceptor(config: config),
      retryInterceptor(dio: dio),
    ];
  }

  AuthInterceptor authInterceptor({
    required IONIdentityConfig config,
  }) {
    return AuthInterceptor(
      dio: NetworkServiceLocator()._refreshTokenDio(config),
      delegatedLoginService: AuthClientServiceLocator().delegatedLogin(config: config),
    );
  }

  RetryInterceptor retryInterceptor({
    required Dio dio,
  }) {
    const retryDelays = [
      Duration(milliseconds: 200),
      Duration(milliseconds: 400),
      Duration(milliseconds: 600),
      Duration(milliseconds: 800),
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 3),
      Duration(seconds: 4),
      Duration(seconds: 5),
    ];
    return RetryInterceptor(
      dio: dio,
      retries: retryDelays.length,
      retryDelays: retryDelays,
    );
  }
}

const _defaultSecureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

mixin _TokenStorage {
  TokenStorage? _tokenStorageInstance;
  FlutterSecureStorage? _flutterSecureStorage;

  TokenStorage tokenStorage() {
    if (_tokenStorageInstance != null) {
      return _tokenStorageInstance!;
    }

    _tokenStorageInstance = TokenStorage(
      secureStorage: flutterSecureStorage(),
    );
    return _tokenStorageInstance!;
  }

  FlutterSecureStorage flutterSecureStorage() {
    if (_flutterSecureStorage != null) {
      return _flutterSecureStorage!;
    }

    _flutterSecureStorage = _defaultSecureStorage;
    return _flutterSecureStorage!;
  }
}

mixin _PrivateKeyStorage {
  PrivateKeyStorage? _privateKeyStorageInstance;
  FlutterSecureStorage? _flutterSecureStorage;

  PrivateKeyStorage privateKeyStorage() {
    if (_privateKeyStorageInstance != null) {
      return _privateKeyStorageInstance!;
    }

    _privateKeyStorageInstance = PrivateKeyStorage(
      secureStorage: flutterSecureStorage(),
    );
    return _privateKeyStorageInstance!;
  }

  FlutterSecureStorage flutterSecureStorage() {
    if (_flutterSecureStorage != null) {
      return _flutterSecureStorage!;
    }

    _flutterSecureStorage = _defaultSecureStorage;
    return _flutterSecureStorage!;
  }
}

mixin _BiometricsStateStorage {
  BiometricsStateStorage? _biometricsStateStorageInstance;
  FlutterSecureStorage? _flutterSecureStorage;

  BiometricsStateStorage biometricsStateStorage() {
    if (_biometricsStateStorageInstance != null) {
      return _biometricsStateStorageInstance!;
    }

    _biometricsStateStorageInstance = BiometricsStateStorage(
      secureStorage: flutterSecureStorage(),
    );
    return _biometricsStateStorageInstance!;
  }

  FlutterSecureStorage flutterSecureStorage() {
    if (_flutterSecureStorage != null) {
      return _flutterSecureStorage!;
    }

    _flutterSecureStorage = _defaultSecureStorage;
    return _flutterSecureStorage!;
  }
}

mixin _LocalPasskeyCredsStateStorage {
  LocalPasskeyCredsStateStorage? _localPasskeyCredsStateStorageInstance;
  FlutterSecureStorage? _flutterSecureStorage;

  LocalPasskeyCredsStateStorage localPasskeyCredsStateStorage() {
    if (_localPasskeyCredsStateStorageInstance != null) {
      return _localPasskeyCredsStateStorageInstance!;
    }

    _localPasskeyCredsStateStorageInstance = LocalPasskeyCredsStateStorage(
      secureStorage: flutterSecureStorage(),
    );
    return _localPasskeyCredsStateStorageInstance!;
  }

  FlutterSecureStorage flutterSecureStorage() {
    if (_flutterSecureStorage != null) {
      return _flutterSecureStorage!;
    }

    _flutterSecureStorage = _defaultSecureStorage;
    return _flutterSecureStorage!;
  }
}

mixin _NetworkClient {
  NetworkClient? _networkClient;

  NetworkClient networkClient({
    required IONIdentityConfig config,
  }) {
    if (_networkClient != null) {
      return _networkClient!;
    }

    final dio = NetworkServiceLocator().dio(config: config);

    _networkClient = NetworkClient(dio: dio);

    return _networkClient!;
  }
}
