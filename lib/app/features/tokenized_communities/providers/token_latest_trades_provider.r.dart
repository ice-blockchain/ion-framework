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

  // Dedupe key-set across SSE + REST pages.
  final Set<String> _seenKeys = <String>{};

  // Before the initial REST snapshot loads, we record SSE keys that arrived.
  // After initial REST returns, we can compute which SSE trades were NOT included
  // in that snapshot and must shift subsequent REST offsets.
  final Set<String> _sseKeysBeforeInitial = <String>{};

  // REST pagination state.
  int _restOffset = 0;

  // Number of *new* trades received from SSE since the last successful REST request.
  // This value shifts the REST offset because server-side offsets are from the newest.
  int _sseShift = 0;

  bool _initialLoaded = false;
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
    _seenKeys.clear();
    _sseKeysBeforeInitial.clear();

    _restOffset = offset;
    _sseShift = 0;
    _initialLoaded = false;
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

    // Capture the shift that we are about to account for in this REST request.
    late int shiftAtRequest;
    late int requestOffset;
    await _enqueue(() {
      shiftAtRequest = _sseShift;
      requestOffset = _restOffset + shiftAtRequest;
    });

    try {
      final moreTrades = await client.communityTokens.fetchLatestTrades(
        ionConnectAddress: _masterPubkey,
        limit: _pageSize,
        offset: requestOffset,
      );
      final fetchedCount = moreTrades.length;

      // Even if empty, we have successfully “accounted for” `shiftAtRequest` in the offset.
      await _enqueue(() {
        for (final trade in moreTrades) {
          final key = _tradeKey(trade);
          if (_seenKeys.add(key)) {
            _currentTrades.add(trade);
          }
        }

        _restOffset += moreTrades.length;

        // We consumed `shiftAtRequest` by including it into `requestOffset`.
        // Any SSE trades that arrived during the fetch incremented `_sseShift` meanwhile;
        // keep only those for the next page.
        _sseShift -= shiftAtRequest;
        if (_sseShift < 0) _sseShift = 0;

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
        final initialKeys = <String>{
          for (final t in initialTrades) _tradeKey(t),
        };

        // Append REST snapshot after whatever SSE trades we might have already prepended.
        for (final trade in initialTrades) {
          final key = _tradeKey(trade);
          if (_seenKeys.add(key)) {
            _currentTrades.add(trade);
          }
        }

        // Any SSE trades received *before* the snapshot that were NOT included in it
        // must shift subsequent REST offsets.
        _sseShift = _sseKeysBeforeInitial.difference(initialKeys).length;

        // REST offset advances by the number of rows we asked for / received from REST,
        // independent of dedupe.
        _restOffset = offset + initialTrades.length;

        _initialLoaded = true;
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
              final key = _tradeKey(trade);
              if (_seenKeys.contains(key)) continue;

              _seenKeys.add(key);
              _currentTrades.insert(0, trade);

              if (!_initialLoaded) {
                _sseKeysBeforeInitial.add(key);
              } else {
                // This is a *new* trade after the last REST request -> shifts pagination.
                _sseShift += 1;
              }
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

  String _tradeKey(LatestTrade trade) {
    // `createdAt` + ionConnect address + type + amount gives a stable-enough id and
    // protects against rare same-timestamp collisions.
    return '${trade.position.createdAt}|'
        '${trade.position.addresses.ionConnect}|'
        '${trade.position.type}|'
        '${trade.position.amount}';
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
