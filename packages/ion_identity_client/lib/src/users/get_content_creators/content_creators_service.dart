// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/src/users/get_content_creators/data_sources/get_content_creators_data_source.dart';
import 'package:ion_identity_client/src/users/models/identity_user_info.f.dart';

class IONConnectContentCreatorsService {
  IONConnectContentCreatorsService(
    this.username,
    this._dataSource,
  );

  final String username;
  final IONContentCreatorsDataSource _dataSource;

  Future<List<IdentityUserInfo>> contentCreators({
    required int limit,
    required List<String> excludeMasterPubKeys,
  }) async =>
      _dataSource.fetchIONContentCreators(
        username: username,
        limit: limit,
        excludeMasterPubKeys: excludeMasterPubKeys,
      );
}
