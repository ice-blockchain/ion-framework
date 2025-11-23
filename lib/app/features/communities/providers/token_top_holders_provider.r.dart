// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart' as analytics;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_top_holders_provider.r.g.dart';

@riverpod
class TokenTopHolders extends _$TokenTopHolders {
  @override
  Stream<List<analytics.TopHolder>> build(
    String masterPubkey, {
    required int limit,
  }) async* {
    final client = await ref.watch(ionTokenAnalyticsClientProvider.future);
    final subscription = await client.communityTokens.subscribeToTopHolders(
      ionConnectAddress: masterPubkey,
      limit: limit,
    );

    ref.onDispose(subscription.close);

    // Buffer for the initial load
    final initialItems = <analytics.TopHolder>[];
    var isInitialLoad = true;
    var currentList = <analytics.TopHolder>[];

    await for (final newTopHolder in subscription.stream) {
      if (isInitialLoad) {
        if (newTopHolder.isEmpty()) {
          // End of initial load
          isInitialLoad = false;
          currentList = List.from(initialItems);
          // Sort by rank initially if needed
          // currentList.sort((a, b) => a.position.rank.compareTo(b.position.rank));
          yield currentList;
        } else {
          // Accumulate items
          if (newTopHolder is analytics.TopHolder) {
            initialItems.add(newTopHolder);
          }
        }
      } else {
        // Update phase
        final existIndex = currentList.indexWhere(
          (element) => element.position.addresses.ionConnect == newTopHolder.position?.addresses?.ionConnect,
        );

        if (existIndex >= 0) {
          final existHolder = currentList[existIndex];

          final existJson = existHolder.toJson();
          final patchJson = newTopHolder.toJson();

          existJson.addAll(patchJson);

          final patchedHolder = analytics.TopHolder.fromJson(existJson);

          // Create a new list reference for state update
          currentList = List.from(currentList);
          currentList[existIndex] = patchedHolder;

          currentList.sort((a, b) => a.position.rank.compareTo(b.position.rank));
          yield currentList;
        } else {
          // New item added after initial load
          if (newTopHolder is analytics.TopHolder) {
            final newList = List<analytics.TopHolder>.from(currentList)
              ..insert(0, newTopHolder)
              ..sort((a, b) => a.position.rank.compareTo(b.position.rank));
            yield newList;
          }
        }
      }
    }
  }
}
