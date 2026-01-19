// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/utils/logging.dart';
import 'package:ion/app/utils/proxy_host.dart';

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
    List<String> proxyDomains = const <String>[],
    String? initialPreferredProxyDomain,
    FutureOr<void> Function(String? domain)? persistPreferredProxyDomain,
    int proxyPort = 443,
  })  : _checkInterval = checkInterval,
        _checkNoInternetInterval = checkNoInternetInterval,
        _internetCheckOptions = options,
        _confirmDisconnectDelay = confirmDisconnectDelay,
        _proxyDomains = proxyDomains,
        _preferredProxyDomain = initialPreferredProxyDomain,
        _persistPreferredProxyDomain = persistPreferredProxyDomain,
        _proxyPort = proxyPort {
    _statusStreamController.onListen = _maybeEmitStatusUpdate;
    _statusStreamController.onCancel = _handleStatusChangeCancel;
  }

  Stream<InternetStatus> get onStatusChange => _statusStreamController.stream;

  final Duration _checkInterval;
  final Duration _checkNoInternetInterval;
  final List<InternetCheckOption> _internetCheckOptions;
  final Duration _confirmDisconnectDelay;

  final List<String> _proxyDomains;
  String? _preferredProxyDomain;
  final FutureOr<void> Function(String? domain)? _persistPreferredProxyDomain;
  final int _proxyPort;

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
    // 1) Fast-path: try saved preferred proxy domain first (if any).
    final preferred = _preferredProxyDomain?.trim();
    if (preferred != null && preferred.isNotEmpty) {
      final ok = await _hasProxyAccessForDomain(preferred);
      if (ok) {
        await _persistPreferredProxyDomainSafe(preferred);
        return true;
      }

      await _persistPreferredProxyDomainSafe(null);
      _preferredProxyDomain = null;
    }

    // 2) Direct connectivity checks (existing behavior).
    for (final option in _internetCheckOptions) {
      final isSuccess = await _dialHost(option);
      if (isSuccess) {
        // Direct connectivity is available; clear any proxy preference.
        await _persistPreferredProxyDomainSafe(null);
        _preferredProxyDomain = null;
        return true;
      }
    }

    // 3) Proxy failover checks (only if direct checks failed).
    for (final domain in _proxyDomains) {
      final normalized = domain.trim();
      if (normalized.isEmpty) continue;

      final ok = await _hasProxyAccessForDomain(normalized);
      if (ok) {
        reportFailover(
          Exception(
            '[Internet] Connectivity failover via proxy domain: $normalized',
          ),
          StackTrace.current,
          tag: 'internet_failover_to_proxy',
        );

        _preferredProxyDomain = normalized;
        await _persistPreferredProxyDomainSafe(normalized);
        return true;
      }
    }

    return false;
  }

  Future<bool> _hasProxyAccessForDomain(String domain) async {
    // Build and dial proxy hosts derived from the configured IP targets.
    for (final option in _internetCheckOptions) {
      final ip = _extractHost(option.host);
      if (ip.isEmpty) continue;

      final proxyHost = buildProxyHostForIp(ip: ip, domain: domain);
      final proxyOption = InternetCheckOption(
        host: proxyHost,
        port: _proxyPort,
        timeout: option.timeout,
      );

      final ok = await _dialHost(proxyOption);
      if (ok) {
        return true;
      }
    }

    return false;
  }

  Future<void> _persistPreferredProxyDomainSafe(String? domain) async {
    final persist = _persistPreferredProxyDomain;
    if (persist == null) return;

    try {
      final result = persist(domain);
      if (result is Future) {
        await result;
      }
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: '[Internet] failed to persist preferred proxy domain',
      );
    }
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
    _preferredProxyDomain = null;
  }
}
