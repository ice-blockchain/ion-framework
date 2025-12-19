// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/token_info/models/community_token.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/position.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/pricing_response.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/token_info_repository.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class TokenInfoRepositoryImpl implements TokenInfoRepository {
  TokenInfoRepositoryImpl(this.client);

  final NetworkClient client;

  @override
  Future<CommunityToken?> getTokenInfo(String externalAddress) async {
    try {
      final tokensRawData = await client.get<List<dynamic>>(
        '/v1/community-tokens/',
        queryParameters: {'externalAddresses': externalAddress},
      );

      final tokenRawData = tokensRawData.firstOrNull;
      if (tokenRawData == null) {
        return null;
      }

      return CommunityToken.fromJson(tokenRawData as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Position?> getHolderPosition(
    String tokenExternalAddress,
    String holderExternalAddress,
  ) async {
    try {
      final positionsRawData = await client.get<List<dynamic>>(
        '/v1/community-tokens/$tokenExternalAddress/positions',
        queryParameters: {'externalHolderAddresses': holderExternalAddress},
      );

      final positionRawData = positionsRawData.firstOrNull;
      if (positionRawData == null) {
        return null;
      }

      return Position.fromJson(positionRawData as Map<String, dynamic>);
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

  @override
  Future<PricingResponse?> getPricing(String externalAddress, String type, String amount) async {
    try {
      final pricingRawData = await client.get<Map<String, dynamic>>(
        '/v1/community-tokens/$externalAddress/pricing',
        queryParameters: {'type': type, 'amount': amount},
      );

      return PricingResponse.fromJson(pricingRawData);
    } catch (e) {
      return null;
    }
  }
}
