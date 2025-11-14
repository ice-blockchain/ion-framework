// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

import 'package:http2/http2.dart';
import 'package:ion_token_analytics/src/http2_client/http2_exceptions.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_connection_status.dart';

/// Manages an HTTP/2 connection.
///
/// Example usage:
/// ```dart
/// final connection = Http2Connection('example.com', port: 443);
/// await connection.connect();
/// await connection.disconnect();
/// ```
///
/// TODO: Add reconnect logic
class Http2Connection {
  /// Creates an HTTP/2 connection manager.
  ///
  /// Does not automatically connect. Call [connect] to establish the connection.
  Http2Connection(this.host, {this.port = 443, this.scheme = 'https'});

  final String host;
  final int port;
  final String scheme;

  ClientTransportConnection? _transport;
  SecureSocket? _socket;

  final _statusController = StreamController<ConnectionStatus>.broadcast(sync: true);
  ConnectionStatus _currentStatus = const ConnectionStatusDisconnected();

  /// Gets the underlying HTTP/2 transport connection.
  ///
  /// This is exposed for creating WebSocket connections.
  /// Returns null if the connection is not yet established.
  ClientTransportConnection? get transport => _transport;

  /// Stream of connection status changes.
  ///
  /// Emits status updates as the connection progresses through its lifecycle.
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  /// Gets the current connection status.
  ConnectionStatus get status => _currentStatus;

  /// Waits for the connection to be established.
  ///
  /// Completes when the connection is ready or throws the exception if connection fails.
  Future<void> _waitForConnected() async {
    if (_currentStatus is ConnectionStatusConnected) {
      return;
    }

    if (_currentStatus case ConnectionStatusDisconnected(exception: final exception?)) {
      throw exception;
    }

    await for (final status in statusStream) {
      if (status is ConnectionStatusConnected) {
        return;
      }
      if (status case ConnectionStatusDisconnected(exception: final exception?)) {
        throw exception;
      }
    }
  }

  void _updateStatus(ConnectionStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// Establishes the HTTP/2 connection.
  Future<void> connect() async {
    if (_currentStatus is ConnectionStatusConnected) {
      return;
    }

    if (_currentStatus is ConnectionStatusConnecting) {
      return _waitForConnected();
    }

    _updateStatus(const ConnectionStatusConnecting());

    try {
      _socket = await SecureSocket.connect(host, port, supportedProtocols: const ['h2']);
      _transport = ClientTransportConnection.viaSocket(_socket!);
      _updateStatus(const ConnectionStatusConnected());
    } catch (e) {
      final exception = Http2ConnectionException(host, port, e.toString());
      _updateStatus(ConnectionStatusDisconnected(exception));
      _socket = null;
      _transport = null;
      rethrow;
    }
  }

  /// Disconnects the HTTP/2 connection.
  Future<void> disconnect() async {
    if (_currentStatus is ConnectionStatusDisconnected ||
        _currentStatus is ConnectionStatusDisconnecting) {
      return;
    }

    _updateStatus(const ConnectionStatusDisconnecting());

    try {
      await _transport?.terminate();
    } finally {
      _transport = null;
    }

    try {
      await _socket?.close();
    } finally {
      _socket = null;
    }

    _updateStatus(const ConnectionStatusDisconnected());
  }

  /// Closes the connection and releases all resources.
  ///
  /// This should be called when the connection is no longer needed.
  /// After calling this method, the connection cannot be reused.
  Future<void> dispose() async {
    await disconnect();
    await _statusController.close();
  }
}
