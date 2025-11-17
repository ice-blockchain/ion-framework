// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_token_analytics_client_provider.r.g.dart';

@Riverpod(keepAlive: true)
Future<IonTokenAnalyticsClient> ionTokenAnalyticsClient(Ref ref) async {
  // TODO: Replace with actual base URL from environment config
  const baseUrl = '';

  return IonTokenAnalyticsClient.create(
    options: IonTokenAnalyticsClientOptions(baseUrl: baseUrl),
  );
}
