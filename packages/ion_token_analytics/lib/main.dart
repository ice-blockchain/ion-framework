#!/usr/bin/env dart

import 'dart:io';

import 'package:http2/http2.dart';

Future<WebSocket?> connectWebSocketOverHttp2(Uri uri) async {
  final socket = await SecureSocket.connect(uri.host, uri.port, supportedProtocols: ['h2']);

  final transport = ClientTransportConnection.viaSocket(socket);

  // RFC 8441 WebSocket over HTTP/2 handshake
  final stream = transport.makeRequest([
    Header.ascii(':method', 'CONNECT'),
    Header.ascii(':protocol', 'websocket'),
    Header.ascii(':scheme', 'https'),
    Header.ascii(':path', uri.path),
    Header.ascii(':authority', uri.host),
    Header.ascii('sec-websocket-version', '13'),
    Header.ascii('sec-websocket-key', 'dGhlIHNhbXBsZSBub25jZQ=='),
  ], endStream: false);

  // Listen for response headers
  await for (final message in stream.incomingMessages) {
    if (message is HeadersStreamMessage) {
      final headers = {
        for (final header in message.headers)
          String.fromCharCodes(header.name): String.fromCharCodes(header.value),
      };

      final status = headers[':status'];
      if (status == '200') {
        print('WebSocket handshake successful');

        // Create WebSocket from the HTTP/2 stream
        final webSocket = WebSocket.fromUpgradedSocket(socket, serverSide: false);

        return webSocket;
      } else {
        print('WebSocket handshake failed with status: $status');
        await socket.close();
        return null;
      }
    }
  }

  await socket.close();
  return null;
}

Future<void> main() async {
  final uri = Uri.parse('ws://154.145.21.11');

  final webSocket = await connectWebSocketOverHttp2(uri);

  if (webSocket != null) {
    print('WebSocket connected!');

    // Example usage
    webSocket.listen(
      (data) {
        print('Received: $data');
      },
      onError: (error) {
        print('Error: $error');
      },
      onDone: () {
        print('WebSocket closed');
      },
    );

    // Send a message
    webSocket.add('Hello, WebSocket!');
  } else {
    print('Failed to establish WebSocket connection');
  }
}
