// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/top_holders/models/models.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

abstract class TopHoldersRepository {
  Future<NetworkSubscription<List<TopHolder>>> subscribeToTopHolders(String ionConnectAddress);
}
