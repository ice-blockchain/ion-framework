// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_top_holders_provider.r.g.dart';

@riverpod
class TokenTopHolders extends _$TokenTopHolders {
  static const int maxLimit = 200;

  @override
  Stream<List<TopHolder>> build(
    String masterPubkey, {
    required int limit,
  }) async* {
    final effectiveLimit = limit.clamp(1, maxLimit);
    final clientFuture = ref.watch(ionTokenAnalyticsClientProvider.future);

    var disposed = false;
    NetworkSubscription<List<TopHolderBase>>? active;

    ref.onDispose(() {
      disposed = true;
      // Best-effort close.
      try {
        active?.close();
      } catch (_) {
        // ignore
      }
      active = null;
    });

    final list = <TopHolder>[];

    // Keep reconnecting forever while the provider is alive.
    while (!disposed) {
      try {
        final client = await clientFuture;
        final subscription = await client.communityTokens.subscribeToTopHolders(
          ionConnectAddress: masterPubkey,
          limit: effectiveLimit,
        );
        active = subscription;

        await for (final batch in subscription.stream) {
          if (disposed) break;
          if (batch.isEmpty) continue; // marker / no-op

          for (final item in batch) {
            if (item is TopHolderPatch) {
              _applyPatchEvent(list, item);
            } else if (item is TopHolder) {
              _applyEvent(list, item);
            }
          }

          // Keep the observed window bounded (top `effectiveLimit`).
          if (list.length > effectiveLimit) {
            list.length = effectiveLimit;
          }

          yield List<TopHolder>.unmodifiable(list);
        }
      } catch (e, st) {
        // Don’t fail the provider; keep showing the last known holders.
        Logger.error(e, stackTrace: st, message: 'Top holders subscription failed; reconnecting');
      } finally {
        try {
          await active?.close();
        } catch (_) {
          // ignore
        }
        active = null;
      }
    }
  }

  void _applyPatchEvent(List<TopHolder> list, TopHolderPatch item) {
    if (item.isEmpty()) {
      return;
    }
    // we expect patches come always with rank present and update only amount.
    // if some holder rank changes should come whole new TopHolder event
    final rank = item.position?.rank;
    if (rank == null) {
      return;
    }
    final index = list.indexWhere((e) => e.position.rank == rank);
    if (index != -1) {
      list[index] = list[index].merge(item);
    }
  }

  void _applyEvent(List<TopHolder> list, TopHolder item) {
    final movedFrom = _indexByHolderIdentity(list, item);
    if (movedFrom != -1) {
      list.removeAt(movedFrom);
    }

    final rank = item.position.rank;
    final insertAt = (rank - 1).clamp(0, list.length);
    list.insert(insertAt, item);

    _normalizeRanks(list);
  }

  void _normalizeRanks(List<TopHolder> list) {
    for (var i = 0; i < list.length; i++) {
      final desiredRank = i + 1;
      final current = list[i];
      if (current.position.rank != desiredRank) {
        list[i] = current.copyWith(
          position: current.position.copyWith(rank: desiredRank),
        );
      }
    }
  }

  int _indexByHolderIdentity(List<TopHolder> list, TopHolder incoming) {
    final key = _occupantKey(incoming);
    if (key == null || key.isEmpty) return -1;
    return list.indexWhere((e) => _occupantKey(e) == key);
  }

  String? _occupantKey(TopHolder h) {
    return h.position.holder.addresses?.ionConnect ?? h.position.holder.addresses?.twitter;
  }
}
