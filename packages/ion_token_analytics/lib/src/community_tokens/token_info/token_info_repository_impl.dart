// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/token_info/models/community_token.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/token_info_repository.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class TokenInfoRepositoryImpl implements TokenInfoRepository {
  TokenInfoRepositoryImpl(this.client);

  final NetworkClient client;

  @override
  Future<CommunityToken?> getTokenInfo(String externalAddress) async {
    try {
      final data = await client.get<List<dynamic>>(
        '/v1/community-tokens/',
        queryParameters: {'externalAddresses': externalAddress},
      );

      return data.map((json) => CommunityToken.fromJson(json as Map<String, dynamic>)).firstOrNull;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<NetworkSubscription<CommunityTokenPatch>?> subscribeToTokenInfo(
    String externalAddress,
  ) async {
    try {
      final subscription = await client.subscribeSse<Map<String, dynamic>>(
        '/v1sse/community-tokens/',
        queryParameters: {'externalAddresses': externalAddress},
      );

      final tokenStream = subscription.stream.map(CommunityTokenPatch.fromJson);

      return NetworkSubscription<CommunityTokenPatch>(
        stream: tokenStream,
        close: subscription.close,
      );
    } catch (e) {
      return null;
    }
  }
}
