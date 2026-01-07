// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/service_locator/ion_identity_clients/auth_client_service_locator.dart';
import 'package:ion_identity_client/src/core/service_locator/ion_identity_clients/coin_client_service_locator.dart';
import 'package:ion_identity_client/src/core/service_locator/ion_identity_clients/deeplinks_client_service_locator.dart';
import 'package:ion_identity_client/src/core/service_locator/ion_identity_clients/keys_client_service_locator.dart';
import 'package:ion_identity_client/src/core/service_locator/ion_identity_clients/networks_client_service_locator.dart';
import 'package:ion_identity_client/src/core/service_locator/ion_identity_clients/statistics_client_service_locator.dart';
import 'package:ion_identity_client/src/core/service_locator/ion_identity_clients/users_client_service_locator.dart';
import 'package:ion_identity_client/src/core/service_locator/ion_identity_clients/wallets_client_service_locator.dart';
import 'package:ion_identity_client/src/signer/identity_signer.dart';

class ClientsServiceLocator {
  factory ClientsServiceLocator() {
    return _instance;
  }

  ClientsServiceLocator._internal();

  static final ClientsServiceLocator _instance = ClientsServiceLocator._internal();

  final Map<String, IONIdentityClient> _clients = {};

  IONIdentityClient ionIdentityClient({
    required String username,
    required IONIdentityConfig config,
    required IdentitySigner identitySigner,
  }) {
    var client = _clients[username];
    if (client == null) {
      client = IONIdentityClient(
        username: username,
        config: config,
        identitySigner: identitySigner,
        auth: AuthClientServiceLocator().auth(
          username: username,
          config: config,
          identitySigner: identitySigner,
        ),
        wallets: WalletsClientServiceLocator().wallets(
          username: username,
          config: config,
          identitySigner: identitySigner,
        ),
        users: UsersClientServiceLocator().users(
          username: username,
          config: config,
        ),
        coins: CoinsClientServiceLocator().coins(
          username: username,
          config: config,
        ),
        networks: NetworksClientServiceLocator().networks(
          username: username,
          config: config,
        ),
        statistics: StatisticsClientServiceLocator().statistics(
          username: username,
          config: config,
        ),
        keys: KeysClientServiceLocator().keys(
          username: username,
          config: config,
          identitySigner: identitySigner,
        ),
        deeplinks: DeeplinksClientServiceLocator().deeplinks(
          username: username,
          config: config,
        ),
      );
      _clients[username] = client;
    }
    return client;
  }
}
