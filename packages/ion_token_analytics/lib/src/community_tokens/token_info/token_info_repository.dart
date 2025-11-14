// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/token_info/models/community_token.f.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

abstract class TokenInfoRepository {
  Future<List<CommunityToken>> getTokenInfo(List<String> ionConnectAddresses);

  Future<NetworkSubscription<List<CommunityToken>>> subscribeToTokenInfo(
    List<String> ionConnectAddresses,
  );
}
