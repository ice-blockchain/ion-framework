// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/network/utils.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/http_method.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';
import 'package:ion_identity_client/src/signer/dtos/dtos.dart';
import 'package:ion_identity_client/src/signer/types/user_action_signing_request.dart';

class UserActionSignerDataSource {
  const UserActionSignerDataSource({
    required this.networkClient,
    required this.tokenStorage,
  });

  final NetworkClient networkClient;
  final TokenStorage tokenStorage;

  static const initPath = '/auth/action/init';
  static const completePath = '/auth/action';

  Future<UserActionChallenge> createUserActionSigningChallenge(
    String username,
    UserActionSigningInitRequest request,
  ) {
    final token = tokenStorage.getToken(username: username);
    if (token == null) {
      throw const UnauthenticatedException();
    }

    return networkClient.post(
      initPath,
      data: request.toJson(),
      headers: RequestHeaders.getAuthorizationHeaders(
        token: token.token,
        username: username,
      ),
      decoder: (result, _) => parseJsonObject(result, fromJson: UserActionChallenge.fromJson),
    );
  }

  Future<String> createUserActionSignature(
    String username,
    AssertionRequestData assertion,
    String challengeIdentifier,
  ) {
    final token = tokenStorage.getToken(username: username);
    if (token == null) {
      throw const UnauthenticatedException();
    }

    final requestData = UserActionSigningCompleteRequest(
      challengeIdentifier: challengeIdentifier,
      firstFactor: assertion,
    );

    return networkClient.post(
      completePath,
      data: requestData.toJson(),
      headers: RequestHeaders.getAuthorizationHeaders(
        token: token.token,
        username: username,
      ),
      decoder: (response, _) => response['userAction'] as String,
    );
  }

  Future<T> makeRequest<T>(
    String username,
    String signature,
    UserActionSigningRequest request,
    T Function(JsonObject) responseDecoder,
  ) {
    final token = tokenStorage.getToken(username: username);
    if (token == null) {
      throw const UnauthenticatedException();
    }

    final headers = {
      ...RequestHeaders.getAuthorizationHeaders(
        token: token.token,
        username: username,
      ),
      RequestHeaders.ionIdentityUserAction: signature,
    };

    return switch (request.method) {
      HttpMethod.post => networkClient.post(
          request.path,
          data: request.body,
          headers: headers,
          decoder: (result, _) => parseJsonObject(result, fromJson: responseDecoder),
        ),
      HttpMethod.put => networkClient.put(
          request.path,
          data: request.body,
          headers: headers,
          decoder: (result, _) => parseJsonObject(result, fromJson: responseDecoder),
        ),
      _ => throw UnimplementedError('Method ${request.method} is not supported'),
    };
  }
}
