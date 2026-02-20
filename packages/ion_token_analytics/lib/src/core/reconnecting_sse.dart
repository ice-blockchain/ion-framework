// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:math' as math;

import 'package:ion_token_analytics/src/core/logger.dart';
import 'package:ion_token_analytics/src/http2_client/http2_exceptions.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_subscription.dart';

/// Internal state of [ReconnectingSse].
enum _SseState { listening, reconnecting, closed }

/// Manages a reconnecting SSE stream that automatically retries on connection errors.
///
/// Handles:
/// - Automatic reconnection with exponential backoff (capped at [maxRetries])
/// - `<nil>` marker handling for Go-based SSE endpoints
/// - Concurrent reconnection attempt prevention
/// - Stale connection detection
class ReconnectingSse<T> {
  ReconnectingSse({
    required Http2Subscription<T> initialSubscription,
    required Future<Http2Subscription<T>> Function() createSubscription,
    required String path,
    AnalyticsLogger? logger,
    Future<void> Function()? onStaleConnection,
    this.maxRetries = 50,
  }) : _createSubscription = createSubscription,
       _path = path,
       _logger = logger,
       _onStaleConnection = onStaleConnection {
    _currentSubscription = initialSubscription;
    _listenToSubscription(initialSubscription);
  }

  final Future<Http2Subscription<T>> Function() _createSubscription;
  final String _path;
  final AnalyticsLogger? _logger;
  final Future<void> Function()? _onStaleConnection;

  /// Maximum number of consecutive reconnection attempts before giving up.
  final int maxRetries;

  final _controller = StreamController<T>.broadcast();
  late Http2Subscription<T> _currentSubscription;
  StreamSubscription<T>? _currentListener;

  _SseState _state = _SseState.listening;
  int _reconnectAttempts = 0;

  static const _maxRetryDelayMs = 10000;

  Stream<T> get stream => _controller.stream;

  Future<void> close() async {
    if (_state == _SseState.closed) return;
    _logger?.log('[ReconnectingSse] Closing SSE subscription for path: $_path');
    _state = _SseState.closed;
    await _currentListener?.cancel();
    try {
      await _currentSubscription.close();
    } catch (e) {
      _logger?.log(
        '[ReconnectingSse] Error closing subscription (ignored) for path: $_path: $e',
      );
    }
    if (!_controller.isClosed) await _controller.close();
  }

  void _listenToSubscription(Http2Subscription<T> sub) {
    _currentSubscription = sub;
    _currentListener?.cancel();

    _currentListener = sub.stream.listen(
      (data) {
        if (_state == _SseState.closed) return;
        if (_reconnectAttempts > 0) {
          _logger?.log(
            '[ReconnectingSse] Reconnection successful after $_reconnectAttempts attempt(s) for path: $_path',
          );
        }
        _controller.add(data);
        _reconnectAttempts = 0;
      },
      onError: (Object error, StackTrace stackTrace) async {
        if (_state == _SseState.closed) return;

        if (_handleDisposed(error)) return;

        // Handle <nil> marker from Go SSE endpoints
        if (error is FormatException && error.toString().contains('<nil>')) {
          _logger?.log('[ReconnectingSse] Received <nil> marker on SSE stream for path: $_path');
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

        _logger?.log('[ReconnectingSse] Connection error for path: $_path: $error');
        await _handleStaleConnectionIfNeeded(error);
        _triggerReconnection();
      },
      onDone: () {
        _logger?.log('[ReconnectingSse] SSE stream closed (onDone) for path: $_path');
        if (_state == _SseState.listening) {
          _logger?.log(
            '[ReconnectingSse] Stream completed unexpectedly, attempting reconnection for path: $_path',
          );
          _triggerReconnection();
        }
      },
      cancelOnError: false,
    );
  }

  void _triggerReconnection() {
    if (_state != _SseState.listening) return;
    unawaited(_reconnectionLoop());
  }

  Future<void> _reconnectionLoop() async {
    _state = _SseState.reconnecting;

    while (_state == _SseState.reconnecting) {
      _reconnectAttempts++;

      if (_reconnectAttempts > maxRetries) {
        _logger?.log(
          '[ReconnectingSse] Max retries ($maxRetries) exceeded for path: $_path — giving up',
        );
        _state = _SseState.closed;
        if (!_controller.isClosed) {
          _controller.addError(
            Exception('ReconnectingSse: max retries ($maxRetries) exceeded for $_path'),
          );
          await _controller.close();
        }
        return;
      }

      _logger?.log(
        '[ReconnectingSse] Attempting reconnection $_reconnectAttempts/$maxRetries for path: $_path',
      );

      try {
        await _currentSubscription.close();
      } catch (e) {
        _logger?.log(
          '[ReconnectingSse] Error closing old subscription (ignored) for path: $_path: $e',
        );
      }

      final delayMs = math.min(
        _maxRetryDelayMs,
        (200 * math.pow(2, _reconnectAttempts - 1)).toInt(),
      );
      _logger?.log(
        '[ReconnectingSse] Waiting ${delayMs}ms before retry for path: $_path',
      );
      await Future<void>.delayed(Duration(milliseconds: delayMs));

      if (_state == _SseState.closed) return;

      try {
        final newSub = await _createSubscription();
        if (_state == _SseState.closed) {
          await newSub.close();
          return;
        }

        _logger?.log(
          '[ReconnectingSse] New subscription created successfully for path: $_path',
        );

        _state = _SseState.listening;
        _listenToSubscription(newSub);
        return;
      } catch (e) {
        if (_handleDisposed(e)) return;

        _logger?.log(
          '[ReconnectingSse] Reconnection attempt $_reconnectAttempts failed for path: $_path: $e',
        );
        await _handleStaleConnectionIfNeeded(e);
        // Loop continues
      }
    }
  }

  /// Returns true if [error] is a disposed exception — closes the stream gracefully.
  bool _handleDisposed(Object error) {
    if (error is Http2ClientDisposedException) {
      _logger?.log(
        '[ReconnectingSse] Client disposed, closing stream gracefully for path: $_path',
      );
      _state = _SseState.closed;
      if (!_controller.isClosed) _controller.close();
      return true;
    }
    return false;
  }

  Future<void> _handleStaleConnectionIfNeeded(Object error) async {
    if (_onStaleConnection == null) return;

    final isStale =
        error is Http2StaleConnectionException ||
        Http2StaleConnectionException.isStaleConnectionError(error);

    if (isStale) {
      _logger?.log(
        '[ReconnectingSse] Detected stale connection, forcing disconnect for path: $_path',
      );
      try {
        await _onStaleConnection();
      } catch (e) {
        _logger?.log(
          '[ReconnectingSse] Error during force disconnect (ignored) for path: $_path: $e',
        );
      }
    }
  }
}
