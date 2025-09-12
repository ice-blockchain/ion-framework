// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/auth/services/twofa/models/init_twofa_request.f.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/network/utils.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';
import 'package:sprintf/sprintf.dart';

class TwoFADataSource {
  const TwoFADataSource({
    required this.networkClient,
    required this.tokenStorage,
  });

  final NetworkClient networkClient;
  final TokenStorage tokenStorage;

  /// {userID}, {twoFAOption}
  static const twoFaPath = '/v1/users/%s/2fa/%s/verification-requests';

  /// {userID}, {twoFAOption}, {twoFAOptionValue}
  static const deleteTwoFaPath = '/v1/users/%s/2fa/%s/values/%s';

  static const queryOption = 'twoFAOptionVerificationValue';
  static const queryValue = 'twoFAOptionVerificationCode';

  Future<Map<String, dynamic>> requestTwoFACode({
    required String username,
    required String userId,
    required String twoFAOption,
    Map<String, String>? verificationCodes,
    String? signature,
    String? email,
    String? phoneNumber,
    String? replace,
  }) async {
    try {
      final token = tokenStorage.getToken(username: username)?.token;
      if (token == null && signature != null) {
        throw const UnauthenticatedException();
      }

      final body = InitTwoFARequest(
        verificationCodes: verificationCodes,
        email: email,
        phoneNumber: phoneNumber,
        replace: replace,
      );

      return await networkClient.put(
        sprintf(twoFaPath, [userId, twoFAOption]),
        data: body.toJson(),
        headers: token == null
            ? {}
            : {
                ...RequestHeaders.getAuthorizationHeaders(token: token, username: username),
                RequestHeaders.ionIdentityUserAction: signature,
              },
        decoder: (json, _) => parseJsonObject(json, fromJson: (json) => json),
      );
    } on RequestExecutionException catch (e) {
      final exception = _mapException(e);
      throw exception;
    }
  }

  Future<Map<String, dynamic>> verifyTwoFA({
    required String username,
    required String userId,
    required String twoFAOption,
    required String code,
  }) async {
    try {
      final token = tokenStorage.getToken(username: username)?.token;
      if (token == null) {
        throw const UnauthenticatedException();
      }

      return await networkClient.patch(
        sprintf(twoFaPath, [userId, twoFAOption]),
        queryParams: {'code': code},
        headers: RequestHeaders.getAuthorizationHeaders(token: token, username: username),
        decoder: (json, _) => parseJsonObject(json, fromJson: (json) => json),
      );
    } on RequestExecutionException catch (e) {
      final exception = _mapException(e);
      throw exception;
    }
  }

  Future<void> deleteTwoFA({
    required String username,
    required String userId,
    required TwoFAType twoFAType,
    String? signature,
    List<TwoFAType> verificationCodes = const [],
  }) async {
    try {
      final token = tokenStorage.getToken(username: username)?.token;
      if (token == null && signature != null) {
        throw const UnauthenticatedException();
      }

      final query = verificationCodes
          .map(
            (e) => '$queryOption=${e.option}&$queryValue=${e.value!}',
          )
          .join('&');
      final twoFaValue = twoFAType.value ?? 0;
      final uri = Uri.parse(networkClient.dio.options.baseUrl)
          .resolveUri(
            Uri(
              path: sprintf(deleteTwoFaPath, [userId, twoFAType.option, twoFaValue]),
              query: query,
            ),
          )
          .toString();

      return await networkClient.delete<void>(
        uri,
        headers: token == null
            ? {}
            : {
                ...RequestHeaders.getAuthorizationHeaders(token: token, username: username),
                RequestHeaders.ionIdentityUserAction: signature,
              },
        decoder: (response, _) => response,
      );
    } on RequestExecutionException catch (e) {
      final exception = _mapException(e);
      throw exception;
    }
  }

  Exception _mapException(RequestExecutionException e) {
    if (e.error is! DioException) return e;

    final exception = e.error as DioException;
    if (TwoFaMethodNotConfiguredException.isMatch(exception)) {
      return TwoFaMethodNotConfiguredException();
    }
    if (InvalidTwoFaCodeException.isMatch(exception)) {
      return InvalidTwoFaCodeException();
    }
    if (InvalidSignatureException.isMatch(exception)) {
      return InvalidSignatureException();
    }

    return e;
  }
}
