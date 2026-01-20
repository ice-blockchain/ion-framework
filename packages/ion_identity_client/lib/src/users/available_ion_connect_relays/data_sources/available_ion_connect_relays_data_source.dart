// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/network/utils.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/request_headers.dart';
import 'package:ion_identity_client/src/users/available_ion_connect_relays/models/available_ion_connect_relays_response.f.dart';

String normalizeRelayUrlNo443(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null) return raw.trim();

  // Only strip explicit :443 for secure websockets.
  if (uri.scheme == 'wss' && uri.hasPort && uri.port == 443) {
    return uri.replace(port: 0).toString(); // port:0 removes the explicit port
  }

  return uri.toString();
}

class AvailableIONConnectRelaysDataSource {
  AvailableIONConnectRelaysDataSource(
    this._networkClient,
    this._tokenStorage,
  );

  final NetworkClient _networkClient;
  final TokenStorage _tokenStorage;

  static const basePath = '/v1/users';

  Future<List<IonConnectRelayInfo>> fetchAllAvailableIONConnectRelays({
    required String username,
    required String userId,
    required String relayUrl,
  }) async {
    final token = _tokenStorage.getToken(username: username);
    if (token == null) {
      throw const UnauthenticatedException();
    }

    final response = await _networkClient.get(
      '$basePath/$userId/all-available-ion-connect-relays',
      headers: RequestHeaders.getTokenHeader(
        token: token.token,
      ),
      queryParams: {'ion-connect-relay': normalizeRelayUrlNo443(relayUrl)},
      decoder: (result, _) =>
          parseJsonObject(result, fromJson: AvailableIONConnectRelaysResponse.fromJson),
    );

    return response.ionConnectRelays;
  }
}
