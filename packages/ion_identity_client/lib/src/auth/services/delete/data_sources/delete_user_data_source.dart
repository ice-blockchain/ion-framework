// SPDX-License-Identifier: ice License 1.0
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';

class DeleteUserDataSource {
  DeleteUserDataSource({
    required this.networkClient,
  });

  final NetworkClient networkClient;

  static const deletePath = '/auth/users';

  Future<void> deleteUser({
    required String userId,
    required String username,
    required String token,
    required String base64Kind5Event,
  }) async {
    return networkClient.delete<void>(
      '$deletePath/$userId',
      decoder: (response, _) => response,
      headers: {
        ...RequestHeaders.getAuthorizationHeaders(
          token: token,
          username: username,
        ),
        'X-Useraction': base64Kind5Event,
      },
    );
  }
}
