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
    final initialItems = <TopHolder>[];
    var isInitialLoad = true;
    var currentList = <TopHolder>[];

    await for (final newTopHolder in subscription.stream) {
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
        // Update phase
        final existIndex = currentList.indexWhere(
          (element) =>
              element.position.addresses.ionConnect == newTopHolder.position?.addresses?.ionConnect,
        );

        if (existIndex >= 0) {
          final existHolder = currentList[existIndex];
          if (newTopHolder is TopHolderPatch) {
            final patchedHolder = existHolder.merge(newTopHolder);

            // Create a new list reference for state update
            currentList = List.from(currentList);
            currentList[existIndex] = patchedHolder;
          } else if (newTopHolder is TopHolder) {
            currentList = List.from(currentList);
            currentList[existIndex] = newTopHolder;
          }

          currentList.sort((a, b) => a.position.rank.compareTo(b.position.rank));
          yield currentList;
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
