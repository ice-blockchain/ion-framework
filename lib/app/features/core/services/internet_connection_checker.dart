// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

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
      _statusStreamController.add(currentStatus);
    }

    _timerHandle = Timer(_checkInterval, _maybeEmitStatusUpdate);

    _lastStatus = currentStatus;
  }

  Future<InternetStatus> _currentStatus() async {
    return await _hasInternetAccess() ? InternetStatus.connected : InternetStatus.disconnected;
  }

  Future<bool> _hasInternetAccess() async {
    final futures = _internetCheckOptions.map(_dialHost);
    return Stream.fromFutures(futures).firstWhere(
      (isSuccess) => isSuccess,
      orElse: () => false,
    );
  }

  Future<bool> _dialHost(InternetCheckOption option) async {
    try {
      final socket = await Socket.connect(
        _extractHost(option.host),
        option.port,
        timeout: option.timeout,
      );
      await socket.close();
      return true;
    } catch (_) {
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
    _timerHandle?.cancel();
    _timerHandle = null;
    _lastStatus = null;
  }
}
