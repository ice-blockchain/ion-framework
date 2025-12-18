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

    var currentList = <TopHolder>[];
    var isInitialLoad = true;

    await for (final batch in subscription.stream) {
      final workingList = List<TopHolder>.from(currentList);
      var shouldEmit = false;

      if (batch.isEmpty) {
        isInitialLoad = false;
        shouldEmit = true;
      }

      for (final item in batch) {
        if (isInitialLoad && item is TopHolderPatch && item.isEmpty()) {
          isInitialLoad = false;
          shouldEmit = true;
          continue;
        }

        if (isInitialLoad) {
          if (item is TopHolder) {
            workingList.add(item);

            if (workingList.length >= limit) {
              isInitialLoad = false;
            }
            shouldEmit = true;
          }
        } else {
          _applyUpdate(workingList, item);
          shouldEmit = true;
        }
      }

      if (shouldEmit) {
        _sortAndEnforceLimit(workingList, limit);
        currentList = workingList;
        yield currentList;
      }
    }
  }

  void _applyUpdate(List<TopHolder> list, TopHolderBase item) {
    final rank = item.position?.rank;
    if (rank == null) {
      return;
    }

    final index = list.indexWhere((element) => element.position.rank == rank);
    if (index != -1) {
      final existing = list[index];
      if (item is TopHolderPatch) {
        list[index] = existing.merge(item);
      } else if (item is TopHolder) {
        list[index] = item;
      }
    } else if (item is TopHolder) {
      list.add(item);
    }
  }

  void _sortAndEnforceLimit(List<TopHolder> list, int limit) {
    list.sort((a, b) => a.position.rank.compareTo(b.position.rank));
    if (list.length > limit) {
      list.length = limit;
    }
  }
}
