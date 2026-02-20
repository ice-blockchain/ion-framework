// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swap_restricted_region_probe_service.r.g.dart';

@riverpod
SwapRestrictedRegionProbeService swapRestrictedRegionProbeService(Ref ref) {
  return SwapRestrictedRegionProbeService(ref);
}

class SwapRestrictedRegionProbeService {
  const SwapRestrictedRegionProbeService(this._ref);

  final Ref _ref;

  Future<RestrictedRegionException?> probe() async {
    Logger.info('[SwapRestrictedRegionProbeService] Starting restricted region probe');
    try {
      final identityClient = await _ref.read(ionIdentityClientProvider.future);

      await identityClient.wallets.probeRestrictedRegion();
      Logger.info('[SwapRestrictedRegionProbeService] Probe completed without restrictions');
      return null;
    } on RestrictedRegionException catch (error) {
      Logger.warning('[SwapRestrictedRegionProbeService] Restricted region detected: $error');
      return error;
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: '[SwapRestrictedRegionProbeService] Probe failed with non-restricted error',
      );
      return null;
    }
  }
}
