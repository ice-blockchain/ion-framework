import 'dart:io';

import 'package:http2/http2.dart';

/// Manages an HTTP/2 connection that can be used to create multiple WebSocket connections.
///
/// Example usage:
/// ```dart
/// final connection = await Http2Connection.connect('example.com', 4443);
/// ```
class Http2Connection {
  Http2Connection._(this._transport, this.host, this.scheme);

  final ClientTransportConnection _transport;
  final String host;
  final String scheme;
  bool _closed = false;

  /// Gets the underlying HTTP/2 transport connection.
  ///
  /// This is exposed for creating WebSocket connections.
  ClientTransportConnection get transport => _transport;

  /// Connects to a server and creates an HTTP/2 connection.
  ///
  /// The [host] is the server hostname.
  /// The [port] defaults to 443 for secure connections.
  /// The [scheme] should be 'wss' for WebSocket over TLS.
  static Future<Http2Connection> connect(
    String host, {
    int port = 443,
    String scheme = 'https',
  }) async {
    try {
      final socket = await SecureSocket.connect(host, port, supportedProtocols: const ['h2']);
      final transport = ClientTransportConnection.viaSocket(socket);
      return Http2Connection._(transport, host, scheme);
    } catch (e, stackTrace) {
      print('HTTP/2 connection error: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Closes the HTTP/2 connection.
  ///
  /// After closing, no new WebSocket connections can be created.
  /// Existing WebSocket connections will continue to work until they are individually closed.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _transport.finish();
  }
}
