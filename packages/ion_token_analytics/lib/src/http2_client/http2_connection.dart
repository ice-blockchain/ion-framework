import 'dart:async';
import 'dart:io';

import 'package:http2/http2.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_connection_status.dart';
import 'package:ion_token_analytics/src/http2_client/web_socket_exceptions.dart';

/// Manages an HTTP/2 connection that can be used to create multiple WebSocket connections.
///
/// Example usage:
/// ```dart
/// final connection = Http2Connection('example.com', port: 443);
/// await connection.connect();
/// ```
class Http2Connection {
  /// Creates an HTTP/2 connection manager.
  ///
  /// Does not automatically connect. Call [connect] to establish the connection.
  Http2Connection(this.host, {this.port = 443, this.scheme = 'https'});

  final String host;
  final int port;
  final String scheme;

  ClientTransportConnection? _transport;

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
    // If already connected, return immediately
    if (_currentStatus is ConnectionStatusConnected) {
      return;
    }

    // If already disconnected, throw the exception if present
    if (_currentStatus case ConnectionStatusDisconnected(exception: final exception?)) {
      throw exception;
    }

    // Wait for a status change
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
  ///
  /// If already connected, returns immediately. Otherwise, attempts to connect
  /// to the server. Can be called multiple times safely.
  Future<void> connect() async {
    // If already connected, return immediately
    if (_currentStatus is ConnectionStatusConnected) {
      return;
    }

    // If currently connecting, wait for completion
    if (_currentStatus is ConnectionStatusConnecting) {
      return _waitForConnected();
    }

    _updateStatus(const ConnectionStatusConnecting());

    try {
      final socket = await SecureSocket.connect(host, port, supportedProtocols: const ['h2']);
      _transport = ClientTransportConnection.viaSocket(socket);
      _updateStatus(const ConnectionStatusConnected());
    } catch (e) {
      final exception = Http2ConnectionException(host, port, e.toString());
      _updateStatus(ConnectionStatusDisconnected(exception));
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

    if (_transport != null) {
      try {
        await _transport!.finish();
      } finally {
        _transport = null;
      }
    }

    _updateStatus(const ConnectionStatusDisconnected());
  }
}
