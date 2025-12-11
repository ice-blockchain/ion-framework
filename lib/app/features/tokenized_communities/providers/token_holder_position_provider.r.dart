// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_holder_position_provider.r.g.dart';

@riverpod
Future<Position?> tokenHolderPosition(
  Ref ref,
  String tokenExternalAddress,
  String holderExternalAddress,
) async {
  try {
    final client = await ref.watch(ionTokenAnalyticsClientProvider.future);

    final position =
        await client.communityTokens.getHolderPosition(tokenExternalAddress, holderExternalAddress);

    return position;
  } catch (e) {
    return null;
  }
}
