// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/network/utils.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';

class RegisterDataSource {
  const RegisterDataSource({
    required this.networkClient,
  });

  final NetworkClient networkClient;

  static const registerInitPath = '/auth/registration/delegated';
  static const registerCompletePath = '/auth/registration/enduser';
  static const emailAvailabilityForEarlyAccessPath = '/v1/early-access-users';

  Future<void> verifyEmailEarlyAccess({
    required String email,
  }) async {
    try {
      await networkClient.get(
        emailAvailabilityForEarlyAccessPath,
        queryParams: {'email': email},
        decoder: (json, _) => json,
      );
    } on RequestExecutionException catch (e) {
      final exception = _mapException(e);
      throw exception;
    }
  }

  Future<UserRegistrationChallenge> registerInit({
    required String username,
    String? earlyAccessEmail,
  }) async {
    return networkClient.post(
      registerInitPath,
      data: RegisterInitRequest(email: username, earlyAccessEmail: earlyAccessEmail).toJson(),
      decoder: (result, _) => parseJsonObject(result, fromJson: UserRegistrationChallenge.fromJson),
    );
  }

  Future<RegistrationCompleteResponse> registerComplete({
    required CredentialRequestData credentialData,
    required String temporaryAuthenticationToken,
    String? earlyAccessEmail,
  }) {
    return networkClient.post(
      registerCompletePath,
      data:
          SignedChallenge(firstFactorCredential: credentialData, earlyAccessEmail: earlyAccessEmail)
              .toJson(),
      decoder: (result, _) =>
          parseJsonObject(result, fromJson: RegistrationCompleteResponse.fromJson),
      headers: RequestHeaders.getTokenHeader(token: temporaryAuthenticationToken),
    );
  }

  Exception _mapException(RequestExecutionException e) {
    if (e.error is! DioException) return e;

    final exception = e.error as DioException;
    if (InvalidEmailException.isMatch(exception)) {
      return InvalidEmailException();
    }

    return e;
  }
}
