// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_holdings_provider.r.g.dart';

@riverpod
Future<UserHoldingsData> userHoldings(
  Ref ref,
  String holder, {
  int limit = 5,
  int offset = 0,
}) async {
  final client = await ref.watch(ionTokenAnalyticsClientProvider.future);
  return client.communityTokens.getUserHoldings(
    holder: holder,
    limit: limit,
    offset: offset,
  );
}
