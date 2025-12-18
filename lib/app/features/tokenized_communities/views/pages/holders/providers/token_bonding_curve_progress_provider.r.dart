// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_bonding_curve_progress_provider.r.g.dart';

@riverpod
class TokenBondingCurveProgress extends _$TokenBondingCurveProgress {
  @override
  Stream<BondingCurveProgress?> build(String externalAddress) async* {
    final client = await ref.watch(ionTokenAnalyticsClientProvider.future);

    final subscription = await client.communityTokens.subscribeToBondingCurveProgress(
      externalAddress: externalAddress,
    );

    ref.onDispose(subscription.close);

    BondingCurveProgress? current;

    await for (final event in subscription.stream) {
      if (event is BondingCurveProgress) {
        current = event;
        yield current;
        continue;
      }

      if (event is BondingCurveProgressPatch) {
        // We can't materialize a full object from a patch alone.
        if (current == null) continue;

        current = current.merge(event);
        yield current;
      }
    }
  }
}
