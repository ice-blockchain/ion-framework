// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:ion_token_analytics/src/community_tokens/bonding_curve_progress/bonding_curve_progress_repository.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class BondingCurveProgressRepositoryImpl implements BondingCurveProgressRepository {
  BondingCurveProgressRepositoryImpl(this._client);

  final NetworkClient _client;

  @override
  Future<NetworkSubscription<BondingCurveProgressBase>> subscribeToBondingCurveProgress(
    String externalAddress,
  ) async {
    // This endpoint streams either full objects or patches.
    final subscription = await _client.subscribeSse<Map<String, dynamic>>(
      '/v1sse/community-tokens/$externalAddress/bondingCurveProgress',
    );

    final stream = subscription.stream.map((json) {
      try {
        return BondingCurveProgress.fromJson(json);
      } catch (_) {
        return BondingCurveProgressPatch.fromJson(json);
      }
    });

    return NetworkSubscription(stream: stream, close: subscription.close);
  }
}
