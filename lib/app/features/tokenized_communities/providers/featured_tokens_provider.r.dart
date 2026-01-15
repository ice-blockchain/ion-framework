// SPDX-License-Identifier: ice License 1.0

import 'dart:ui';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'featured_tokens_provider.r.g.dart';

@riverpod
Stream<List<CommunityToken>> featuredTokens(Ref ref) async* {
  ref.listen(appLifecycleProvider, (previous, next) {
    if (next == AppLifecycleState.resumed) {
      ref.invalidateSelf();
    }
  });
  final client = await ref.watch(ionTokenAnalyticsClientProvider.future);
  final subscription = await client.communityTokens.subscribeToFeaturedTokens();

  try {
    yield* subscription.stream;
  } finally {
    await subscription.close();
  }
}
