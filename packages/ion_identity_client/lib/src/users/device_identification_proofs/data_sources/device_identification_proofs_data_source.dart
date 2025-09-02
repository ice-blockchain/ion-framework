// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';

class DeviceIdentificationProofsDataSource {
  DeviceIdentificationProofsDataSource(
    this._networkClient,
    this._tokenStorage,
  );

  final NetworkClient _networkClient;
  final TokenStorage _tokenStorage;

  static const basePath = '/v1';

  Future<List<Map<String, dynamic>>> getDeviceIdentificationProofs({
    required String username,
    required String userId,
    required Map<String, dynamic> eventJsonPayload,
  }) async {
    final token = _tokenStorage.getToken(username: username);
    if (token == null) {
      throw const UnauthenticatedException();
    }

    return _networkClient.post<List<Map<String, dynamic>>>(
      '$basePath/device-identification-proofs',
      data: {
        'event': eventJsonPayload,
      },
      headers: RequestHeaders.getAuthorizationHeaders(
        username: username,
        token: token.token,
      ),
      decoder: (result) {
        if (result is List) {
          return result.cast<Map<String, dynamic>>();
        }
        throw const FormatException(
          'Unexpected response shape from /v1/device-identification-proofs',
        );
      },
    );
  }
}
