// SPDX-License-Identifier: ice License 1.0
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/network/utils.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';
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
    required String requestId,
  }) {
    final requestData = UserActionSigningCompleteRequest(
      challengeIdentifier: challengeIdentifier,
      firstFactor: assertion,
    );

    return networkClient.post(
      loginCompletePath,
      data: requestData.toJson(),
      headers: {
        RequestHeaders.deviceIdentificationRequestId: requestId,
      },
      decoder: (result, _) => parseJsonObject(result, fromJson: Authentication.fromJson),
    );
  }
}
