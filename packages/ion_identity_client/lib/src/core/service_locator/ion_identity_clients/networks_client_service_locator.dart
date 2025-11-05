// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/service_locator/ion_identity_service_locator.dart';
import 'package:ion_identity_client/src/networks/ion_identity_networks.dart';
import 'package:ion_identity_client/src/networks/services/get_estimate_fees/data_sources/get_estimate_fees_data_source.dart';
import 'package:ion_identity_client/src/networks/services/get_estimate_fees/get_estimate_fees_service.dart';

class NetworksClientServiceLocator {
  factory NetworksClientServiceLocator() {
    return _instance;
  }

  NetworksClientServiceLocator._internal();

  static final NetworksClientServiceLocator _instance = NetworksClientServiceLocator._internal();

  IONIdentityNetworks networks({
    required String username,
    required IONIdentityConfig config,
  }) {
    return IONIdentityNetworks(
      username: username,
      getEstimateFeesService: getEstimateFees(
        username: username,
        config: config,
      ),
    );
  }

  GetEstimateFeesService getEstimateFees({
    required String username,
    required IONIdentityConfig config,
  }) {
    return GetEstimateFeesService(
      username: username,
      dataSource: GetEstimateFeesDataSource(
        IONIdentityServiceLocator.networkClient(config: config),
        IONIdentityServiceLocator.tokenStorage(),
      ),
    );
  }
}
