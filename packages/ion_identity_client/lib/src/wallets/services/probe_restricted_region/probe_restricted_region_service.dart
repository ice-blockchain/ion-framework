// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/src/wallets/services/probe_restricted_region/data_sources/probe_restricted_region_data_source.dart';

class ProbeRestrictedRegionService {
  const ProbeRestrictedRegionService({
    required ProbeRestrictedRegionDataSource probeRestrictedRegionDataSource,
  }) : _probeRestrictedRegionDataSource = probeRestrictedRegionDataSource;

  final ProbeRestrictedRegionDataSource _probeRestrictedRegionDataSource;

  Future<void> probe() {
    return _probeRestrictedRegionDataSource.probe();
  }
}
