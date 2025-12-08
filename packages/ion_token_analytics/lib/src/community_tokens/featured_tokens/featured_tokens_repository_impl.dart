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
    final subscription = await _client.subscribeSse<List<dynamic>>(
      '/v1sse/community-tokens/featured',
      queryParameters: type != null ? {'type': type} : null,
    );

    final stream = subscription.stream.map(
      (jsonList) =>
          jsonList.map((json) => CommunityToken.fromJson(json as Map<String, dynamic>)).toList(),
    );

    return NetworkSubscription<List<CommunityToken>>(stream: stream, close: subscription.close);
  }
}
