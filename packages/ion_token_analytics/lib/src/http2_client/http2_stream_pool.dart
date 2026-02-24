// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

/// A concurrency limiter for HTTP/2 streams.
///
/// Prevents exceeding the server's max concurrent streams limit by
/// queueing [acquire] calls when at capacity. Uses a direct handoff
/// pattern: when a lease is released and waiters exist, the slot is
/// transferred directly — no wasted wakeups.
class Http2StreamPool {
  Http2StreamPool({this.maxConcurrentStreams = 100, this.onLog});

  /// The maximum number of streams that can be active simultaneously.
  /// Defaults to 100 to leave headroom below the typical server limit of 100.
  final int maxConcurrentStreams;

  /// Optional log callback for stream acquire/release events.
  final void Function(String message)? onLog;

  int _activeCount = 0;
  final _waitQueue = <Completer<StreamLease>>[];
  bool _disposed = false;

  int get activeCount => _activeCount;
  bool get isAtCapacity => _activeCount >= maxConcurrentStreams;

  /// Acquires a stream lease. Waits if the pool is at capacity.
  ///
  /// The returned [StreamLease] MUST be released when the stream is done,
  /// typically in a `finally` block or a close callback.
  ///
  /// Throws [StateError] if the pool is disposed, or [TimeoutException]
  /// if [timeout] expires while waiting.
  Future<StreamLease> acquire({Duration timeout = const Duration(seconds: 30)}) async {
    if (_disposed) throw StateError('Http2StreamPool is disposed');

    if (_activeCount < maxConcurrentStreams) {
      _activeCount++;
      onLog?.call('[StreamPool] +stream (active: $_activeCount/$maxConcurrentStreams)');
      return StreamLease._(_releaseOne);
    }

    // At capacity — enqueue and wait for a handoff from _releaseOne
    onLog?.call(
      '[StreamPool] At capacity ($_activeCount/$maxConcurrentStreams), '
      'waiting (queue: ${_waitQueue.length + 1})',
    );

    final completer = Completer<StreamLease>();
    _waitQueue.add(completer);
    try {
      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          _waitQueue.remove(completer);
          throw TimeoutException(
            'Timed out waiting for an available HTTP/2 stream '
            '(active: $_activeCount/$maxConcurrentStreams, waiting: ${_waitQueue.length})',
          );
        },
      );
    } on TimeoutException {
      rethrow;
    }
  }

  /// Called when a [StreamLease] is released.
  ///
  /// If waiters exist, hands the slot directly to the next one (keeping
  /// [_activeCount] constant). Otherwise decrements the count.
  void _releaseOne() {
    if (_waitQueue.isNotEmpty) {
      final waiter = _waitQueue.removeAt(0);
      onLog?.call(
        '[StreamPool] stream handoff '
        '(active: $_activeCount/$maxConcurrentStreams, queue: ${_waitQueue.length})',
      );
      waiter.complete(StreamLease._(_releaseOne));
    } else if (_activeCount > 0) {
      _activeCount--;
      onLog?.call('[StreamPool] -stream (active: $_activeCount/$maxConcurrentStreams)');
    }
  }

  /// Releases all active leases and errors all waiters.
  ///
  /// Use this when the underlying connection is invalidated (e.g., stale
  /// connection detected). Waiters receive an error so they can be retried
  /// by higher-level reconnection logic.
  void forceReleaseAll() {
    final previous = _activeCount;
    _activeCount = 0;
    onLog?.call('[StreamPool] forceReleaseAll (was: $previous)');
    final waiters = List.of(_waitQueue);
    _waitQueue.clear();
    for (final waiter in waiters) {
      if (!waiter.isCompleted) {
        waiter.completeError(StateError('Connection force-disconnected while waiting for stream'));
      }
    }
  }

  void dispose() {
    _disposed = true;
    _activeCount = 0;
    for (final waiter in _waitQueue) {
      if (!waiter.isCompleted) {
        waiter.completeError(StateError('Http2StreamPool disposed'));
      }
    }
    _waitQueue.clear();
  }
}

/// A lease on an HTTP/2 stream slot. Must be [release]d when the stream is done.
///
/// Safe to call [release] multiple times — only the first call has effect.
class StreamLease {
  StreamLease._(this._onRelease);

  final void Function() _onRelease;
  bool _released = false;

  bool get isReleased => _released;

  void release() {
    if (_released) return;
    _released = true;
    _onRelease();
  }
}
