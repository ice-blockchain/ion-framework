// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_top_holders_provider.r.g.dart';

@riverpod
class TokenTopHolders extends _$TokenTopHolders {
  @override
  Stream<List<TopHolder>> build(
    String externalAddress, {
    required int limit,
  }) async* {
    final client = await ref.watch(ionTokenAnalyticsClientProvider.future);
    final subscription = await client.communityTokens.topHoldersRepository.subscribeToTopHolders(
      externalAddress,
      limit: limit,
    );

    ref.onDispose(subscription.close);

    // Buffer for the initial load
    final initialItems = <TopHolder>[];
    var isInitialLoad = true;
    var currentList = <TopHolder>[];

    await for (final newTopHolders in subscription.stream) {
      for (final newTopHolder in newTopHolders) {
        if (isInitialLoad) {
          if (newTopHolder is TopHolderPatch && newTopHolder.isEmpty()) {
            // End of initial load
            isInitialLoad = false;
            // Sort and enforce limit
            initialItems.sort((a, b) => a.position.rank.compareTo(b.position.rank));
            currentList = initialItems.take(limit).toList();

            yield currentList;
          } else {
            // Accumulate items
            if (newTopHolder is TopHolder) {
              initialItems.add(newTopHolder);
            }
          }
        } else {
          // New item added after initial load
          if (newTopHolder is TopHolder) {
            final newList = List<TopHolder>.from(currentList)
              ..insert(0, newTopHolder)
              ..sort((a, b) => a.position.rank.compareTo(b.position.rank));

            // Enforce limit
            if (newList.length > limit) {
              currentList = newList.sublist(0, limit);
            } else {
              currentList = newList;
            }
            yield currentList;
          }
        }
      }
    }
  }
}
