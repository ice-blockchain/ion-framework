// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:ion_token_analytics/src/community_tokens/top_holders/top_holders_repository.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class TopHoldersRepositoryImpl implements TopHoldersRepository {
  TopHoldersRepositoryImpl(this._client);

  final NetworkClient _client;

  @override
  Future<NetworkSubscription<List<TopHolderBase>>> subscribeToTopHolders(
    String ionConnectAddress, {
    required int limit,
  }) async {
    try {
      // Subscribe to the raw event stream
      final subscription = await _client.subscribeSse<List<dynamic>>(
        '/v1sse/community-tokens/$ionConnectAddress/top-holders',
        queryParameters: {'limit': limit},
      );

      final stream = subscription.stream.map((jsons) {
        final list = <TopHolderBase>[];
        for (final json in jsons) {
          try {
            final data = TopHolder.fromJson(json as Map<String, dynamic>);
            list.add(data);
          } catch (_) {
            final patch = TopHolderPatch.fromJson(json as Map<String, dynamic>);
            list.add(patch);
          }
        }
        return list;
      });

      return NetworkSubscription(stream: stream, close: subscription.close);
    } catch (e) {
      rethrow;
    }
  }
}
