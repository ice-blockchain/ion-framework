// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/src/users/device_identification_proofs/data_sources/device_identification_proofs_data_source.dart';

class DeviceIdentificationProofsService {
  DeviceIdentificationProofsService(
    this.username,
    this._dataSource,
  );

  final String username;
  final DeviceIdentificationProofsDataSource _dataSource;

  Future<List<Map<String, dynamic>>> getDeviceIdentificationProofs({
    required String userId,
    required Map<String, dynamic> eventJsonPayload,
  }) async =>
      _dataSource.getDeviceIdentificationProofs(
        username: username,
        userId: userId,
        eventJsonPayload: eventJsonPayload,
      );
}
