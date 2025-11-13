import 'dart:async';
import 'dart:io';

import 'package:http2/http2.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_connection_status.dart';
import 'package:ion_token_analytics/src/http2_client/web_socket_exceptions.dart';

/// Manages an HTTP/2 connection that can be used to create multiple WebSocket connections.
///
/// Example usage:
/// ```dart
/// final connection = Http2Connection.connect('example.com', port: 443);
/// await connection.waitForConnected();
/// ```
class Http2Connection {
  /// Creates and starts connecting to a server.
  ///
  /// The connection starts immediately and the status can be monitored
  /// via [statusStream].
  Http2Connection.connect(this.host, {this.port = 443, this.scheme = 'https'}) {
    _connect();
  }

  final String host;
  final int port;
  final String scheme;

  ClientTransportConnection? _transport;
  bool _closed = false;

  final _statusController = StreamController<ConnectionStatus>.broadcast();
  ConnectionStatus _currentStatus = const ConnectionStatusConnecting();

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
  Future<void> waitForConnected() async {
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

  Future<void> _connect() async {
    _updateStatus(const ConnectionStatusConnecting());

    try {
      final socket = await SecureSocket.connect(host, port, supportedProtocols: const ['h2']);
      _transport = ClientTransportConnection.viaSocket(socket);
      _updateStatus(const ConnectionStatusConnected());
    } catch (e) {
      final exception = Http2ConnectionException(host, port, e.toString());
      _updateStatus(ConnectionStatusDisconnected(exception));
    }
  }

  /// Closes the HTTP/2 connection.
  ///
  /// After closing, no new WebSocket connections can be created.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _updateStatus(const ConnectionStatusDisconnecting());

    if (_transport != null) {
      await _transport!.finish();
    }

    _updateStatus(const ConnectionStatusDisconnected());
    await _statusController.close();
  }
}
