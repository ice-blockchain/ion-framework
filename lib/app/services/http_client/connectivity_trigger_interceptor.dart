// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ion/app/features/core/services/internet_connection_checker.dart';

/// An interceptor that only triggers connectivity checks as a side-effect.
class ConnectivitySideEffectInterceptor extends Interceptor {
  ConnectivitySideEffectInterceptor({
    required InternetConnectionChecker internetConnectionChecker,
  }) : _internetConnectionChecker = internetConnectionChecker;

  final InternetConnectionChecker _internetConnectionChecker;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final isNetworkLike = _isNetworkLikeError(err);
    if (isNetworkLike) {
      _triggerCheckNow();
    }
    super.onError(err, handler);
  }

  /// Returns true if the error looks like a connectivity-related failure.
  bool _isNetworkLikeError(DioException err) {
    final type = err.type;
    final error = err.error;
    return type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.receiveTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.connectionError ||
        error is SocketException ||
        error is TimeoutException;
  }

  /// Triggers an immediate connectivity check on the provided checker instance.
  void _triggerCheckNow() {
    unawaited(_internetConnectionChecker.checkNow());
  }
}
