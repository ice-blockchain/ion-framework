// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/token_info/models/community_token.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/token_info_repository.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class TokenInfoRepositoryImpl implements TokenInfoRepository {
  TokenInfoRepositoryImpl(this.client);

  final NetworkClient client;

  @override
  Future<List<CommunityToken>> getTokenInfo(List<String> ionConnectAddresses) async {
    final data = await client.get<List<dynamic>>(
      '/v1/community-tokens',
      queryParameters: {'ionConnectAddresses': ionConnectAddresses},
    );

    return data.map((json) => CommunityToken.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<NetworkSubscription<List<CommunityTokenPatch>>> subscribeToTokenInfo(
    List<String> ionConnectAddresses,
  ) async {
    final subscription = await client.subscribe<List<dynamic>>(
      '/v1/community-tokens',
      queryParameters: {'ionConnectAddresses': ionConnectAddresses},
    );

    final tokenStream = subscription.stream.map(
      (data) =>
          data.map((json) => CommunityTokenPatch.fromJson(json as Map<String, dynamic>)).toList(),
    );

    return NetworkSubscription<List<CommunityTokenPatch>>(
      stream: tokenStream,
      close: subscription.close,
    );
  }
}
