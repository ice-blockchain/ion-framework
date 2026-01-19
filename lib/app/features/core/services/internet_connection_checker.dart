// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

import 'package:ion/app/services/logger/logger.dart';

/// Connectivity status enum compatible with previous usage.
enum InternetStatus {
  connected,
  disconnected,

  /// Paused states used to handle app lifecycle
  pausedAfterConnected,
  pausedAfterDisconnected,
}

/// Options describing a host to check using a low-level TCP dial.
class InternetCheckOption {
  const InternetCheckOption({
    required this.host,
    this.port = 53, // DNS TCP port (works for numeric IPs)
    this.timeout = const Duration(seconds: 8),
  });

  final String host;
  final int port;
  final Duration timeout;
}

/// A lightweight connectivity checker that performs TCP "pings" to the provided targets.
class InternetConnectionChecker {
  InternetConnectionChecker.createInstance({
    required Duration checkInterval,
    required Duration checkNoInternetInterval,
    required List<InternetCheckOption> options,
    Duration confirmDisconnectDelay = const Duration(seconds: 30),
  })  : _checkInterval = checkInterval,
        _checkNoInternetInterval = checkNoInternetInterval,
        _internetCheckOptions = options,
        _confirmDisconnectDelay = confirmDisconnectDelay {
    _statusStreamController.onListen = _maybeEmitStatusUpdate;
    _statusStreamController.onCancel = _handleStatusChangeCancel;
  }

  Stream<InternetStatus> get onStatusChange => _statusStreamController.stream;

  final Duration _checkInterval;
  final Duration _checkNoInternetInterval;
  final List<InternetCheckOption> _internetCheckOptions;
  final Duration _confirmDisconnectDelay;

  InternetStatus? _lastStatus;
  Timer? _timerHandle;
  bool _isAwaitingDisconnectConfirmation = false;

  final _statusStreamController = StreamController<InternetStatus>.broadcast();

  /// Triggers an immediate connectivity check and reschedules the next timer.
  ///
  /// If there are no listeners to [onStatusChange], the check is skipped,
  /// mirroring the lazy behavior of the periodic checks.
  Future<void> checkNow() async {
    await _maybeEmitStatusUpdate();
  }

  Future<void> _maybeEmitStatusUpdate() async {
    _timerHandle?.cancel();

    if (!_statusStreamController.hasListener) {
      return;
    }

    final isConnected = await _hasInternetAccess();
    if (isConnected) {
      _handleConnected();
      return;
    }

    _handleNotConnected();
  }

  void _handleConnected() {
    if (_lastStatus != InternetStatus.connected) {
      Logger.info('[Internet] status changed: connected');
      _statusStreamController.add(InternetStatus.connected);
    }
    _isAwaitingDisconnectConfirmation = false;
    _lastStatus = InternetStatus.connected;
    _scheduleNextCheck(_checkInterval);
  }

  void _handleNotConnected() {
    if (_lastStatus == InternetStatus.disconnected) {
      // Already disconnected: keep regular no-internet checks
      _scheduleNextCheck(_checkNoInternetInterval);
      return;
    }

    if (!_isAwaitingDisconnectConfirmation) {
      _scheduleDisconnectConfirmation();
      return;
    }

    _emitDisconnectedAfterConfirmation();
  }

  void _scheduleDisconnectConfirmation() {
    Logger.info(
      '[Internet] first failure detected; confirming in ${_confirmDisconnectDelay.inSeconds}s',
    );
    _isAwaitingDisconnectConfirmation = true;
    _scheduleNextCheck(_confirmDisconnectDelay);
  }

  void _emitDisconnectedAfterConfirmation() {
    Logger.info('[Internet] confirmation failed; status changed: disconnected');
    _statusStreamController.add(InternetStatus.disconnected);
    _lastStatus = InternetStatus.disconnected;
    _isAwaitingDisconnectConfirmation = false;
    _scheduleNextCheck(_checkNoInternetInterval);
  }

  void _scheduleNextCheck(Duration delay) {
    _timerHandle = Timer(delay, _maybeEmitStatusUpdate);
  }

  Future<bool> _hasInternetAccess() async {
    for (final option in _internetCheckOptions) {
      final isSuccess = await _dialHost(option);
      if (isSuccess) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _dialHost(InternetCheckOption option) async {
    final host = _extractHost(option.host);
    Logger.info(
      '[Internet] dial start: $host:${option.port} (timeout ${option.timeout.inSeconds}s)',
    );
    try {
      final socket = await Socket.connect(
        host,
        option.port,
        timeout: option.timeout,
      );
      await socket.close();
      Logger.info('[Internet] dial success: $host:${option.port}');
      return true;
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: '[Internet] dial failed: $host:${option.port}',
      );
      return false;
    }
  }

  String _extractHost(String input) {
    final uri = Uri.tryParse(input);
    if (uri == null || uri.host.isEmpty) {
      return input;
    }
    return uri.host;
  }

  void _handleStatusChangeCancel() {
    if (_statusStreamController.hasListener) return;
    Logger.info('[Internet] stop listening, cancelling timer');
    _timerHandle?.cancel();
    _timerHandle = null;
    _lastStatus = null;
    _isAwaitingDisconnectConfirmation = false;
  }
}
