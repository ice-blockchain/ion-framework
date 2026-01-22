// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:math' as math;

import 'package:ion_token_analytics/src/core/logger.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_subscription.dart';

/// Manages a reconnecting SSE stream that automatically retries on connection errors.
///
/// Handles:
/// - Automatic reconnection with exponential backoff
/// - <nil> marker handling for Go-based SSE endpoints
/// - Concurrent reconnection attempt prevention
/// - Stream lifecycle management
class ReconnectingSse<T> {
  ReconnectingSse({
    required Http2Subscription<T> initialSubscription,
    required Future<Http2Subscription<T>> Function() createSubscription,
    required String path,
    AnalyticsLogger? logger,
  }) : _initialSubscription = initialSubscription,
       _createSubscription = createSubscription,
       _path = path,
       _logger = logger {
    _currentSubscription = _initialSubscription;
    _initialize();
  }

  final Http2Subscription<T> _initialSubscription;
  final Future<Http2Subscription<T>> Function() _createSubscription;
  final String _path;
  final AnalyticsLogger? _logger;

  final _controller = StreamController<T>.broadcast();
  late Http2Subscription<T> _currentSubscription;
  StreamSubscription<T>? _currentListener;
  var _isClosed = false;
  var _reconnectAttempts = 0;
  var _isReconnecting = false; // Guard to prevent concurrent reconnection attempts
  static const _maxRetryDelayMs = 10000; // 10 seconds max delay

  /// The reconnecting stream that automatically handles reconnections.
  Stream<T> get stream => _controller.stream;

  /// Closes the reconnecting SSE stream and cancels all subscriptions.
  Future<void> close() async {
    if (_isClosed) return;
    _logger?.log('[ReconnectingSse] Closing SSE subscription for path: $_path');
    _isClosed = true;
    await _currentListener?.cancel();
    try {
      await _currentSubscription.close();
    } catch (closeError) {
      _logger?.log(
        '[ReconnectingSse] Error closing subscription (ignored) for path: $_path: $closeError',
      );
    }
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  void _initialize() {
    // Start listening to the initial subscription
    // Use unawaited since this is initialization and we don't need to wait
    unawaited(_listenToSubscription(_initialSubscription));
  }

  Future<void> _listenToSubscription(Http2Subscription<T> sub) async {
    _currentSubscription = sub;

    // Cancel previous listener if exists
    await _currentListener?.cancel();

    _currentListener = sub.stream.listen(
      (data) {
        if (!_controller.isClosed && !_isClosed) {
          if (_reconnectAttempts > 0) {
            _logger?.log(
              '[ReconnectingSse] Reconnection successful after $_reconnectAttempts attempt(s) for path: $_path',
            );
          }
          _controller.add(data);
          _reconnectAttempts = 0; // Reset on successful data
        }
      },
      onError: (Object error, StackTrace stackTrace) async {
        if (_controller.isClosed || _isClosed) return;

        final text = error.toString();
        final isNil = error is FormatException && text.contains('<nil>');

        if (isNil) {
          _logger?.log('[ReconnectingSse] Received <nil> marker on SSE stream for path: $_path');
          // Handle <nil> marker
          if (<String, dynamic>{} is T) {
            _controller.add(<String, dynamic>{} as T);
            return;
          }
          if (<dynamic, dynamic>{} is T) {
            _controller.add(<dynamic, dynamic>{} as T);
            return;
          }
          return;
        }

        _logger?.log('[ReconnectingSse] Connection error on SSE stream for path: $_path: $error');
        _logger?.log('[ReconnectingSse] Stack trace for path: $_path: $stackTrace');

        if (!_isReconnecting) {
          unawaited(_attemptReconnection());
        } else {
          _logger?.log(
            '[ReconnectingSse] Reconnection already in progress, skipping duplicate attempt for path: $_path',
          );
        }
      },
      onDone: () {
        _logger?.log('[ReconnectingSse] SSE stream closed (onDone) for path: $_path');
        if (!_controller.isClosed && !_isClosed && !_isReconnecting) {
          _logger?.log(
            '[ReconnectingSse] Stream completed unexpectedly, attempting reconnection for path: $_path',
          );
          unawaited(_attemptReconnection());
        } else if (_isReconnecting) {
          _logger?.log(
            '[ReconnectingSse] Reconnection already in progress, skipping onDone reconnection for path: $_path',
          );
        }
      },
      cancelOnError: false,
    );
  }

  /// Attempts reconnection using an iterative loop instead of recursion.
  /// This prevents stack overflow from accumulating frames during unlimited retries.
  Future<void> _attemptReconnection() async {
    while (!_controller.isClosed && !_isClosed) {
      // Prevent concurrent reconnection attempts
      if (_isReconnecting) {
        _logger?.log(
          '[ReconnectingSse] Reconnection already in progress, skipping duplicate attempt for path: $_path',
        );
        return;
      }

      _isReconnecting = true;
      _reconnectAttempts++;
      _logger?.log(
        '[ReconnectingSse] Attempting reconnection $_reconnectAttempts for path: $_path',
      );

      try {
        // Close the old subscription
        _logger?.log('[ReconnectingSse] Closing old subscription for path: $_path');
        try {
          await _currentSubscription.close();
        } catch (closeError) {
          _logger?.log(
            '[ReconnectingSse] Error closing old subscription (ignored) for path: $_path: $closeError',
          );
        }

        // Wait before retrying using exponential backoff (capped at maxRetryDelayMs)
        final delayMs = math.min(
          _maxRetryDelayMs,
          (200 * math.pow(2, _reconnectAttempts - 1)).toInt(),
        );
        _logger?.log(
          '[ReconnectingSse] Waiting ${delayMs}ms before retry (exp backoff, attempt $_reconnectAttempts) for path: $_path',
        );
        await Future<void>.delayed(Duration(milliseconds: delayMs));

        if (_controller.isClosed || _isClosed) {
          _isReconnecting = false;
          return;
        }

        // Create a new subscription
        _logger?.log('[ReconnectingSse] Creating new SSE subscription for path: $_path');
        final newSub = await _createSubscription();

        _logger?.log(
          '[ReconnectingSse] New subscription created successfully, resuming stream for path: $_path',
        );

        // Listen to the new subscription - this will handle future errors via _attemptReconnection
        // _listenToSubscription will update _currentSubscription
        await _listenToSubscription(newSub);
        // Note: Do NOT reset _reconnectAttempts here - it will be reset in onData when first data arrives
        // This ensures the success log appears when data arrives after reconnection
        _isReconnecting = false; // Clear flag after successful reconnection

        // Successfully reconnected, exit the loop
        return;
      } catch (reconnectError) {
        _logger?.log(
          '[ReconnectingSse] Reconnection attempt $_reconnectAttempts failed for path: $_path: $reconnectError',
        );
        _logger?.log(
          '[ReconnectingSse] Will retry with exponential backoff (current attempt: $_reconnectAttempts) for path: $_path',
        );
        _isReconnecting = false; // Clear flag before next iteration
        // Loop will continue and retry
      }
    }
  }
}
