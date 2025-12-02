// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/token_info/models/community_token.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/token_info_repository.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class TokenInfoRepositoryImpl implements TokenInfoRepository {
  TokenInfoRepositoryImpl(this.client);

  final NetworkClient client;

  @override
  Future<List<CommunityToken>> getTokenInfo(List<String> ionConnectAddresses) async {
    try {
      final data = await client.get<List<dynamic>>(
        '/v1/community-tokens/',
        queryParameters: {
          'externalAddresses':
              'ion_connect:0:634f8ac52ad90bf8544162fb4f45cc56f1fc91ca1220381e96b68eb792d822ea:',
        },
      );

      return data.map((json) => CommunityToken.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      return [];
    }
  }

  @override
  Future<NetworkSubscription<CommunityTokenPatch>> subscribeToTokenInfo(
    List<String> ionConnectAddresses,
  ) async {
    try {
      final subscription = await client.subscribeSse<Map<String, dynamic>>(
        '/v1sse/community-tokens/',
        queryParameters: {
          'externalAddresses':
              'ion_connect:0:634f8ac52ad90bf8544162fb4f45cc56f1fc91ca1220381e96b68eb792d822ea:',
        },
      );

      final tokenStream = subscription.stream.map(CommunityTokenPatch.fromJson);

      return NetworkSubscription<CommunityTokenPatch>(
        stream: tokenStream,
        close: subscription.close,
      );
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      rethrow;
    }
  }
}
