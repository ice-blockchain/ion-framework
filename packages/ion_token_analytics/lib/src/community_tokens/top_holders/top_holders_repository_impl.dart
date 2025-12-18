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
      final subscription = await _client.subscribeSse<Map<String, dynamic>>(
        '/v1sse/community-tokens/$ionConnectAddress/top-holders',
        queryParameters: {'limit': limit},
      );

      // Each SSE event carries a "Type" and optional "Data" payload.  If "Type"
      // is "eose" it indicates end of the initial stream.  Otherwise, the
      // "Data" field contains either a full TopHolder or a partial update
      // (patch).  Convert each event into a batch of TopHolderBase.
      final stream = subscription.stream.map((event) {
        // Marker / EOSE handling:
        // - The HTTP client may convert Go `Data: nil` into an empty map `{}`.
        // - The server may also send an explicit `{Type: "eose", Data: nil}`.
        if (event.isEmpty) {
          return <TopHolderBase>[];
        }

        final type = (event['Type'] ?? event['type']) as String?;
        if (type == 'eose') {
          // End of initial load: emit an empty batch.
          return <TopHolderBase>[];
        }

        // Determine the JSON payload to decode. Some backends send a top-level
        // object (no Data key) while others wrap it in a Data key.  Fallback to
        // the full event if no Data key is present.
        final data = event.containsKey('Data')
            ? event['Data']
            : (event.containsKey('data') ? event['data'] : event);
        if (data is! Map<String, dynamic>) {
          // Unexpected payload; ignore.
          return <TopHolderBase>[];
        }

        // Try to decode a full TopHolder first.  If that fails, decode a patch.
        try {
          final holder = TopHolder.fromJson(data);
          return <TopHolderBase>[holder];
        } catch (_) {
          try {
            return <TopHolderBase>[TopHolderPatch.fromJson(data)];
          } catch (_) {
            // Unknown event structure; ignore.
            return <TopHolderBase>[];
          }
        }
      });

      return NetworkSubscription(stream: stream, close: subscription.close);
    } catch (e) {
      rethrow;
    }
  }
}
