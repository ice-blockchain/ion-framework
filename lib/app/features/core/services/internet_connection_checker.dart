// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

import 'package:ion/app/services/logger/logger.dart';

/// Connectivity status enum compatible with previous usage.
enum InternetStatus { connected, disconnected }

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
    required List<InternetCheckOption> options,
  })  : _checkInterval = checkInterval,
        _internetCheckOptions = options {
    _statusStreamController.onListen = _maybeEmitStatusUpdate;
    _statusStreamController.onCancel = _handleStatusChangeCancel;
  }

  Stream<InternetStatus> get onStatusChange => _statusStreamController.stream;

  final Duration _checkInterval;
  final List<InternetCheckOption> _internetCheckOptions;

  InternetStatus? _lastStatus;
  Timer? _timerHandle;

  final _statusStreamController = StreamController<InternetStatus>.broadcast();

  Future<void> _maybeEmitStatusUpdate() async {
    _timerHandle?.cancel();

    if (!_statusStreamController.hasListener) {
      return;
    }

    final currentStatus = await _currentStatus();

    if (_lastStatus != currentStatus) {
      Logger.info('[Internet] status changed: ${currentStatus.name}');
      _statusStreamController.add(currentStatus);
    }

    _timerHandle = Timer(_checkInterval, _maybeEmitStatusUpdate);

    _lastStatus = currentStatus;
  }

  Future<InternetStatus> _currentStatus() async {
    return await _hasInternetAccess() ? InternetStatus.connected : InternetStatus.disconnected;
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
  }
}
