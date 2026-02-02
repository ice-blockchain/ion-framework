// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_latest_trades_provider.r.g.dart';

@riverpod
class TokenLatestTrades extends _$TokenLatestTrades {
  late String _masterPubkey;
  late int _pageSize;

  // Trades we currently expose (newest -> oldest).
  List<LatestTrade> _currentTrades = [];

  // REST pagination state.
  int _restOffset = 0;

  bool _disposed = false;

  StreamController<List<LatestTrade>>? _controller;
  NetworkSubscription<List<LatestTradeBase>>? _activeSubscription;
  late Future<IonTokenAnalyticsClient> _clientFuture;

  // Serialize all mutations to `_currentTrades` / offsets to avoid races.
  Future<void> _mutex = Future<void>.value();

  @override
  Stream<List<LatestTrade>> build(
    String masterPubkey, {
    int limit = 10,
    int offset = 0,
  }) {
    _masterPubkey = masterPubkey;
    _pageSize = limit;

    _currentTrades = [];
    _restOffset = offset;
    _disposed = false;

    _clientFuture = ref.watch(ionTokenAnalyticsClientProvider.future);

    final controller = StreamController<List<LatestTrade>>(sync: true);
    _controller = controller;

    ref.onDispose(() {
      _disposed = true;
      // Best-effort close.
      _activeSubscription?.close();
      _activeSubscription = null;
      controller.close();
    });

    // Contract: subscribe first (so we don't miss live trades), then load initial snapshot.
    // Both run concurrently; mutations are serialized via `_enqueue`.
    unawaited(_runSse());
    unawaited(_loadInitial(offset: offset));

    return controller.stream;
  }

  Future<int> loadMore() async {
    if (_disposed) return 0;

    final client = await _clientFuture;

    try {
      final moreTrades = await client.communityTokens.fetchLatestTrades(
        ionConnectAddress: _masterPubkey,
        limit: _pageSize,
        offset: _restOffset,
      );
      final fetchedCount = moreTrades.length;

      await _enqueue(() {
        _currentTrades.addAll(moreTrades);
        _restOffset += moreTrades.length;
        _emit();
      });
      return fetchedCount;
    } catch (e, st) {
      Logger.error(e, stackTrace: st, message: 'Error loading more trades');
      return 0;
    }
  }

  Future<void> _loadInitial({required int offset}) async {
    try {
      final client = await _clientFuture;

      // One-time initial snapshot.
      final initialTrades = await client.communityTokens.fetchLatestTrades(
        ionConnectAddress: _masterPubkey,
        limit: _pageSize,
        offset: offset,
      );

      await _enqueue(() {
        _currentTrades.addAll(initialTrades);
        _restOffset = offset + initialTrades.length;
        _emit();
      });
    } catch (e, st) {
      Logger.error(e, stackTrace: st, message: 'Error loading initial trades');
    }
  }

  Future<void> _runSse() async {
    // Keep reconnecting forever while the provider is alive.
    while (!_disposed) {
      try {
        final client = await _clientFuture;
        final subscription = await client.communityTokens.subscribeToLatestTrades(
          ionConnectAddress: _masterPubkey,
        );
        _activeSubscription = subscription;

        await for (final batch in subscription.stream) {
          if (_disposed) break;
          if (batch.isEmpty) continue;

          await _enqueue(() {
            final updates = batch.whereType<LatestTrade>().toList(growable: false);
            if (updates.isEmpty) return;

            // We want newest at the top. If the backend ever sends a mixed order,
            // sorting ascending + inserting at index 0 preserves correct ordering.
            final sorted = List<LatestTrade>.of(updates)
              ..sort(
                (a, b) => _createdAtAsc(a.position.createdAt, b.position.createdAt),
              );

            for (final trade in sorted) {
              _currentTrades.insert(0, trade);
            }

            _emit();
          });
        }
      } catch (e, st) {
        // Don’t fail the provider; keep showing the last known trades.
        Logger.error(
          e,
          stackTrace: st,
          message: 'Latest trades subscription failed; reconnecting',
        );
      } finally {
        try {
          await _activeSubscription?.close();
        } catch (e, st) {
          // ignore and log error
          Logger.error(
            e,
            stackTrace: st,
            message: '[TokenLatestTrades] Failed to close subscription in _runSse finally block',
          );
        }
        _activeSubscription = null;
      }
    }
  }

  Future<void> _enqueue(FutureOr<void> Function() action) {
    return _mutex = _mutex.catchError((_) {}).then((_) => action());
  }

  void _emit() {
    _sortTrades(); // Ensure consistent ordering
    final controller = _controller;
    if (controller == null || controller.isClosed) return;
    controller.add(List<LatestTrade>.unmodifiable(_currentTrades));
  }

  int _createdAtAsc(String a, String b) {
    final da = DateTime.tryParse(a);
    final db = DateTime.tryParse(b);
    if (da != null && db != null) {
      return da.compareTo(db);
    }
    return a.compareTo(b);
  }

  void _sortTrades() {
    _currentTrades.sort(
      (a, b) => _createdAtAsc(b.position.createdAt, a.position.createdAt),
    );
  }
}
