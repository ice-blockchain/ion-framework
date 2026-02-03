// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/token_info/models/community_token.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/position.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/pricing_response.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/suggest_creation_details_request.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/suggest_creation_details_response.f.dart';
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
    } catch (error, stackTrace) {
      client.logger?.error(
        'Failed to get token info for externalAddress: $externalAddress',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
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
    } catch (error, stackTrace) {
      client.logger?.error(
        'Failed to get holder position for tokenExternalAddress: $tokenExternalAddress, holderExternalAddress: $holderExternalAddress',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<NetworkSubscription<CommunityTokenBase>?> subscribeToTokenInfo(
    String externalAddress,
  ) async {
    try {
      final subscription = await client.subscribeSse<Map<String, dynamic>>(
        '/v1sse/community-tokens/',
        queryParameters: {'externalAddresses': externalAddress},
      );

      final tokenStream = subscription.stream.map<CommunityTokenBase>((data) {
        try {
          return CommunityToken.fromJson(data);
        } catch (_) {
          return CommunityTokenPatch.fromJson(data);
        }
      });

      return NetworkSubscription<CommunityTokenBase>(
        stream: tokenStream,
        close: subscription.close,
      );
    } catch (error, stackTrace) {
      client.logger?.error(
        'Failed to subscribe to token info for externalAddress: $externalAddress',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
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
    } catch (error, stackTrace) {
      client.logger?.error(
        'Failed to get pricing for externalAddress: $externalAddress, type: $type, amount: $amount',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<SuggestCreationDetailsResponse?> suggestCreationDetails(
    SuggestCreationDetailsRequest request,
  ) async {
    try {
      final responseData = await client.post<Map<String, dynamic>>(
        '/v1/community-tokens/suggest-creation-details',
        data: request.toJson(),
      );

      return SuggestCreationDetailsResponse.fromJson(responseData);
    } catch (error, stackTrace) {
      client.logger?.error(
        'Failed to suggest creation details',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
