// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/network/utils.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';

class RecoverUserDataSource {
  RecoverUserDataSource({
    required this.networkClient,
  });

  final NetworkClient networkClient;

  static const createDelegatedRecoveryChallengePath = '/auth/recover/user/delegated';
  static const recoverUserPath = '/auth/recover/user';

  Future<UserRegistrationChallenge> createDelegatedRecoveryChallenge({
    required String username,
    required String credentialId,
    List<TwoFAType>? twoFATypes,
  }) async {
    try {
      return await networkClient.post(
        createDelegatedRecoveryChallengePath,
        data: {
          'username': username,
          'credentialId': credentialId,
          '2FAVerificationCodes': {
            for (final twoFAType in twoFATypes ?? []) twoFAType.option: twoFAType.value,
          },
        },
        decoder: (result, _) =>
            parseJsonObject(result, fromJson: UserRegistrationChallenge.fromJson),
      );
    } on RequestExecutionException catch (e) {
      if (e.error is! DioException) rethrow;

      final exception = e.error as DioException;

      if (TwoFARequiredException.isMatch(exception)) {
        final twoFAOptionsCount = exception.response?.data['data']['n'] as int;
        throw TwoFARequiredException(twoFAOptionsCount);
      }
      if (InvalidTwoFaCodeException.isMatch(exception)) {
        throw InvalidTwoFaCodeException();
      }
      if (InvalidRecoveryCredentialsException.isMatch(exception)) {
        throw InvalidRecoveryCredentialsException();
      }
      rethrow;
    }
  }

  Future<JsonObject> recoverUser({
    required JsonObject recoveryData,
    required String temporaryAuthenticationToken,
  }) {
    return networkClient.post(
      recoverUserPath,
      data: recoveryData,
      headers: RequestHeaders.getTokenHeader(token: temporaryAuthenticationToken),
      decoder: (json, _) => parseJsonObject(json, fromJson: (json) => json),
    );
  }
}
