// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/src/users/ion_connect_relays/data_sources/ion_connect_relays_data_source.dart';
import 'package:ion_identity_client/src/users/models/identity_user_info.f.dart';

class IONConnectRelaysService {
  IONConnectRelaysService(
    this.username,
    this._dataSource,
  );

  final String username;
  final IONConnectRelaysDataSource _dataSource;

  Future<List<IdentityUserInfo>> relays({
    required List<String> masterPubkeys,
  }) async =>
      _dataSource.fetchIONConnectRelays(
        username: username,
        masterPubkeys: masterPubkeys,
      );
}
