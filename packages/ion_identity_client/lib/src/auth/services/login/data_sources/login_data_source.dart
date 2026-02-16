// SPDX-License-Identifier: ice License 1.0
import 'package:dio/dio.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/network/utils.dart';
import 'package:ion_identity_client/src/signer/dtos/dtos.dart';

class LoginDataSource {
  LoginDataSource({
    required this.networkClient,
  });

  final NetworkClient networkClient;

  static const loginInitPath = '/auth/login/init';
  static const loginCompletePath = '/auth/login';

  Future<UserActionChallenge> loginInit({
    String? username,
    List<TwoFAType>? twoFATypes,
  }) async {
    return networkClient.post(
      loginInitPath,
      data: {
        'username': username,
        '2FAVerificationCodes': {
          for (final twoFAType in twoFATypes ?? []) twoFAType.option: twoFAType.value,
        },
      },
      decoder: (result, _) => parseJsonObject(result, fromJson: UserActionChallenge.fromJson),
    );
  }

  Future<Authentication> loginComplete({
    required AssertionRequestData assertion,
    required String challengeIdentifier,
  }) async {
    final requestData = UserActionSigningCompleteRequest(
      challengeIdentifier: challengeIdentifier,
      firstFactor: assertion,
    );

    try {
      return await networkClient.post(
        loginCompletePath,
        data: requestData.toJson(),
        decoder: (result, _) => parseJsonObject(result, fromJson: Authentication.fromJson),
      );
    } on RequestExecutionException catch (e) {
      if (e.error is! DioException) rethrow;

      final exception = e.error as DioException;
      if (InvalidSignatureException.isMatch(exception)) {
        throw InvalidSignatureException(
          'Login signature rejected for credentialId: ${assertion.credentialAssertion.credId}',
        );
      }

      throw RequestExecutionException(
        e.error,
        e.stackTrace,
        'Login complete failed for credentialId: ${assertion.credentialAssertion.credId}',
      );
    }
  }
}
