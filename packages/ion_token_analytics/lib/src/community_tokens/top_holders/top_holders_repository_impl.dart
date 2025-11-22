// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:ion_token_analytics/src/community_tokens/top_holders/top_holders_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/top_holders/top_holders_stream_transformer.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class TopHoldersRepositoryImpl implements TopHoldersRepository {
  TopHoldersRepositoryImpl(this._client);

  final NetworkClient _client;

  @override
  Future<NetworkSubscription<List<TopHolder>>> subscribeToTopHolders(
    String ionConnectAddress, {
    required int limit,
  }) async {
    // Subscribe to the raw event stream
    final subscription = await _client.subscribe<dynamic>(
      '/community-tokens/$ionConnectAddress/top-holders',
      queryParameters: {'limit': limit},
    );

    // Transform the stream using our logic
    final transformedStream = subscription.stream.transform(TopHoldersStreamTransformer(limit));

    return NetworkSubscription(stream: transformedStream, close: subscription.close);
  }
}
