// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:math' as math;

import 'package:ion/app/features/tokenized_communities/providers/latest_trades_accumulator.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_latest_trades_provider.r.g.dart';

@riverpod
class TokenLatestTrades extends _$TokenLatestTrades {
  static const int _reconnectBaseDelayMs = 300;
  static const int _reconnectMaxDelayMs = 5000;

  late String _masterPubkey;
  late int _pageSize;

  final _accumulator = LatestTradesAccumulator();

  // REST pagination state.
  int _restOffset = 0;

  bool _disposed = false;

  /// Incremented on every [build] call so that async work from a previous
  /// build cycle can detect it is stale and bail out early.
  int _generation = 0;

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

    _accumulator.reset();
    _restOffset = offset;
    _disposed = false;

    final generation = ++_generation;

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
    unawaited(_runSse(generation));
    unawaited(_loadInitial(offset: offset, generation: generation));

    return controller.stream;
  }

  Future<int> loadMore() async {
    if (_disposed) return 0;

    final generation = _generation;
    final client = await _clientFuture;
    if (generation != _generation) return 0;

    try {
      final moreTrades = await client.communityTokens.fetchLatestTrades(
        ionConnectAddress: _masterPubkey,
        limit: _pageSize,
        offset: _restOffset,
      );
      if (generation != _generation) return 0;
      final fetchedCount = moreTrades.length;

      await _enqueue(() {
        if (generation != _generation) return;
        _accumulator.appendUnique(moreTrades);
        _restOffset += moreTrades.length;
        _emit();
      });
      return fetchedCount;
    } catch (e, st) {
      Logger.error(e, stackTrace: st, message: 'Error loading more trades');
      return 0;
    }
  }

  Future<void> _loadInitial({required int offset, required int generation}) async {
    try {
      final client = await _clientFuture;
      if (generation != _generation) return;

      // One-time initial snapshot.
      final initialTrades = await client.communityTokens.fetchLatestTrades(
        ionConnectAddress: _masterPubkey,
        limit: _pageSize,
        offset: offset,
      );
      if (generation != _generation) return;

      await _enqueue(() {
        if (generation != _generation) return;
        _accumulator.appendUnique(initialTrades);

        _restOffset = offset + initialTrades.length;
        _emit();
      });
    } catch (e, st) {
      Logger.error(e, stackTrace: st, message: 'Error loading initial trades');
    }
  }

  Future<void> _runSse(int generation) async {
    var reconnectAttempt = 0;

    // Keep reconnecting forever while the provider is alive
    // and this is still the current build cycle.
    while (!_disposed && generation == _generation) {
      // Track the subscription locally so that a stale loop only
      // closes its own subscription, never the one belonging to a
      // newer generation.
      NetworkSubscription<List<LatestTradeBase>>? localSubscription;
      try {
        final client = await _clientFuture;
        if (generation != _generation) break;

        final subscription = await client.communityTokens.subscribeToLatestTrades(
          ionConnectAddress: _masterPubkey,
        );
        if (generation != _generation) {
          await subscription.close();
          break;
        }
        reconnectAttempt = 0;
        localSubscription = subscription;
        _activeSubscription = subscription;

        await for (final batch in subscription.stream) {
          if (_disposed || generation != _generation) break;
          if (batch.isEmpty) continue;

          await _enqueue(() {
            if (generation != _generation) return;

            final updates = batch.whereType<LatestTrade>().toList(growable: false);
            if (updates.isNotEmpty) {
              _accumulator.prependUnique(updates);
            }

            var changed = updates.isNotEmpty;

            final patches = batch.whereType<LatestTradePatch>();
            for (final patch in patches) {
              changed = _accumulator.applyPatch(patch) || changed;
            }

            if (!changed) return;

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
        // Only close the subscription that *this* loop iteration opened.
        // If a newer generation already replaced `_activeSubscription`,
        // we must not null it out or close it.
        try {
          await localSubscription?.close();
        } catch (e, st) {
          Logger.error(
            e,
            stackTrace: st,
            message: '[TokenLatestTrades] Failed to close subscription in _runSse finally block',
          );
        }
        if (_activeSubscription == localSubscription) {
          _activeSubscription = null;
        }
      }

      if (_disposed || generation != _generation) {
        break;
      }

      await Future<void>.delayed(_reconnectDelay(reconnectAttempt));
      reconnectAttempt++;
    }
  }

  Future<void> _enqueue(FutureOr<void> Function() action) {
    return _mutex = _mutex.catchError((_) {}).then((_) => action());
  }

  void _emit() {
    final controller = _controller;
    if (controller == null || controller.isClosed) return;
    controller.add(_accumulator.snapshot());
  }

  Duration _reconnectDelay(int attempt) {
    final exponent = math.min(attempt, 5);
    final millis = math.min(
      _reconnectMaxDelayMs,
      _reconnectBaseDelayMs * (1 << exponent),
    );
    return Duration(milliseconds: millis);
  }
}
