// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:ion_token_analytics/src/community_tokens/featured_tokens/featured_tokens_repository.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class FeaturedTokensRepositoryImpl implements FeaturedTokensRepository {
  FeaturedTokensRepositoryImpl(this._client);

  final NetworkClient _client;

  @override
  Future<NetworkSubscription<List<CommunityToken>>> subscribeToFeaturedTokens({
    String? type,
  }) async {
    final subscription = await _client.subscribeSse<Map<String, dynamic>>(
      '/v1sse/community-tokens/featured',
      queryParameters: type != null ? {'type': type} : null,
    );

    final tokensMap = <String, int>{};
    final tokensList = <CommunityToken>[];

    final stream = subscription.stream.map((data) {
      try {
        final token = CommunityToken.fromJson(data);
        final key = token.addresses.ionConnect;

        if (key == null) {
          // Skip tokens without ionConnect address
          return List<CommunityToken>.from(tokensList);
        }

        final existingIndex = tokensMap[key];

        if (existingIndex != null) {
          // Update existing token
          tokensList[existingIndex] = token;
        } else {
          // Add new token
          tokensList.add(token);
          tokensMap[key] = tokensList.length - 1;
        }
      } catch (e) {
        // Skip invalid tokens
      }

      return List<CommunityToken>.from(tokensList);
    });

    return NetworkSubscription<List<CommunityToken>>(stream: stream, close: subscription.close);
  }
}
