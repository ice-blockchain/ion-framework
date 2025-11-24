// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/ion_token_analytics.dart';

abstract class TopHoldersRepository {
  Future<NetworkSubscription<TopHolderPatch>> subscribeToTopHolders(
    String ionConnectAddress, {
    required int limit,
  });
}
