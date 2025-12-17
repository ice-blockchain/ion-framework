// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:ion_identity_client/src/auth/services/delegated_login/delegated_login_service.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.dio,
    required this.delegatedLoginService,
  });

  final Dio dio;
  final DelegatedLoginService delegatedLoginService;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Extract username from the original request
      final username = _extractUsername(err.requestOptions);

      if (username != null) {
        try {
          // Attempt to refresh the token
          final newToken = await delegatedLoginService.delegatedLogin(username: username);

          // Update the original request with the new token
          final newAuthHeader = RequestHeaders.getTokenHeader(token: newToken.token).entries.first;
          err.requestOptions.headers[newAuthHeader.key] = newAuthHeader.value;

          // Retry the original request
          try {
            final response = await dio.fetch<dynamic>(err.requestOptions);
            return handler.resolve(response);
          } on DioException catch (retryError) {
            return handler.next(retryError);
          }
        } catch (e) {
          // If token refresh fails, continue with the original error
          return handler.next(err);
        }
      }
    }
    // For other errors or if username is not found, continue with the error
    return handler.next(err);
  }

  String? _extractUsername(RequestOptions options) {
    return options.headers['X-Username'] as String?;
  }
}
