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

  late String _masterPubkey;
  late int _pageSize;
  int _currentLimit = 0;

  final List<TopHolder> _holders = <TopHolder>[];

  bool _disposed = false;
  bool _hasMore = true;
  int _generation = 0;

  StreamController<List<TopHolder>>? _controller;
  NetworkSubscription<List<TopHolderBase>>? _activeSubscription;
  late Future<IonTokenAnalyticsClient> _clientFuture;

  Future<void> _mutex = Future<void>.value();

  // Completed when the current subscription emits the marker/EOSE (empty batch).
  Completer<void> _marker = Completer<void>();

  @override
  Stream<List<TopHolder>> build(
    String masterPubkey, {
    required int limit,
  }) {
    _masterPubkey = masterPubkey;
    _pageSize = limit.clamp(1, maxLimit);

    _currentLimit = _pageSize;
    _holders.clear();

    _disposed = false;
    _hasMore = true;
    _generation = 0;

    _marker = Completer<void>();

    _clientFuture = ref.watch(ionTokenAnalyticsClientProvider.future);

    final controller = StreamController<List<TopHolder>>(sync: true);
    _controller = controller;

    ref.onDispose(() {
      _disposed = true;
      // Unblock any pending waits.
      if (!_marker.isCompleted) {
        _marker.complete();
      }
      try {
        _activeSubscription?.close();
      } catch (_) {
        // ignore
      }
      _activeSubscription = null;
      controller.close();
    });

    unawaited(_runSse());

    return controller.stream;
  }

  Future<bool> loadMore() async {
    if (_disposed) return false;

    // Wait until the current subscription finished its initial snapshot.
    await _marker.future;

    // If we already detected the end, don't keep bumping the limit.
    if (!_hasMore) return false;

    if (_currentLimit >= maxLimit) {
      _hasMore = false;
      return false;
    }

    // Capture current list size before increasing the limit.
    late int prevLen;
    await _enqueue(() {
      prevLen = _holders.length;
    });

    await _enqueue(() {
      _currentLimit = (_currentLimit + _pageSize).clamp(1, maxLimit);
    });

    // Restart and wait for the new subscription marker.
    _restartSubscription();
    await _marker.future;

    // If the number of holders did not increase after raising the limit,
    // it means the backend has no more holders to send.
    late int newLen;
    await _enqueue(() {
      newLen = _holders.length;
      if (newLen <= prevLen) {
        _hasMore = false;
        if (_currentLimit > newLen) {
          _currentLimit = newLen;
        }
      }
    });

    return _hasMore;
  }

  void _restartSubscription() {
    _generation += 1;

    // New subscription => wait for its marker/EOSE.
    _marker = Completer<void>();

    try {
      _activeSubscription?.close();
    } catch (_) {
      // ignore
    }
    _activeSubscription = null;
    // _runSse loop will reconnect automatically.
  }

  Future<void> _runSse() async {
    while (!_disposed) {
      final gen = _generation;
      try {
        final client = await _clientFuture;
        final subscription = await client.communityTokens.subscribeToTopHolders(
          ionConnectAddress: _masterPubkey,
          limit: _currentLimit,
        );
        _activeSubscription = subscription;

        await for (final batch in subscription.stream) {
          if (_disposed) break;
          if (gen != _generation) break; // limit changed -> restart
          if (batch.isEmpty) {
            // Marker/EOSE: initial snapshot for this subscription is finished.
            if (!_marker.isCompleted) {
              _marker.complete();
            }
            continue;
          }

          await _enqueue(() {
            for (final item in batch) {
              if (item is TopHolderPatch) {
                _applyPatchEvent(_holders, item);
              } else if (item is TopHolder) {
                _applyEvent(_holders, item);
              }
            }

            if (_holders.length > _currentLimit) {
              _holders.length = _currentLimit;
            }

            _emit();
          });
        }
      } catch (e, st) {
        // Unblock marker waiters so UI can try loadMore again.
        if (!_marker.isCompleted) {
          _marker.complete();
        }

        Logger.error(e, stackTrace: st, message: 'Top holders subscription failed; reconnecting');
      } finally {
        try {
          await _activeSubscription?.close();
        } catch (_) {
          // ignore
        }
        _activeSubscription = null;
      }
    }
  }

  Future<void> _enqueue(FutureOr<void> Function() action) {
    return _mutex = _mutex.catchError((_) {}).then((_) => action());
  }

  void _emit() {
    final controller = _controller;
    if (controller == null || controller.isClosed) return;
    controller.add(List<TopHolder>.unmodifiable(_holders));
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
    return h.position.holder?.addresses?.ionConnect ??
        h.position.holder?.addresses?.twitter ??
        h.position.holder?.addresses?.blockchain ??
        h.position.holder?.name;
  }
}
