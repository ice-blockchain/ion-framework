// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:ion_token_analytics/src/community_tokens/top_holders/top_holders_repository.dart';

class TopHoldersRepositoryImpl implements TopHoldersRepository {
  TopHoldersRepositoryImpl(this._client);

  final NetworkClient _client;

  @override
  Future<NetworkSubscription<TopHolderPatch>> subscribeToTopHolders(
    String ionConnectAddress, {
    required int limit,
  }) async {
    // Subscribe to the raw event stream
    final subscription = await _client.subscribe<Map<String, dynamic>>(
      '/community-tokens/$ionConnectAddress/top-holders',
      queryParameters: {'limit': limit},
    );

    final stream = subscription.stream.map((json) {
      try {
        final data = TopHolder.fromJson(json);
        return data;
      } catch (_) {
        final patch = TopHolderPatch.fromJson(json);
        return patch;
      }
    });

    return NetworkSubscription(stream: stream, close: subscription.close);
  }
}
