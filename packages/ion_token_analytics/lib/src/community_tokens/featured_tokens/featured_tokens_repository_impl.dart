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

    final accumulatedTokens = <CommunityToken>[];

    final stream = subscription.stream.map((data) {
      try {
        final token = CommunityToken.fromJson(data);
        final existingIndex = accumulatedTokens.indexWhere(
          (t) => t.addresses.ionConnect == token.addresses.ionConnect,
        );
        if (existingIndex >= 0) {
          accumulatedTokens[existingIndex] = token;
        } else {
          accumulatedTokens.add(token);
        }
      } catch (e) {
        // Skip invalid tokens
      }

      return List<CommunityToken>.from(accumulatedTokens);
    });

    return NetworkSubscription<List<CommunityToken>>(stream: stream, close: subscription.close);
  }
}
