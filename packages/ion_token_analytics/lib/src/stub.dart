import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http2/http2.dart';
import 'package:ion_token_analytics/src/websocket/models/web_socket_message.dart';

// WebSocket protocol constants (RFC 6455)
class _WebSocketConstants {
  static const int opcodeText = 0x1;
  static const int opcodeBinary = 0x2;
  static const int opcodeClose = 0x8;
  static const int opcodePing = 0x9;
  static const int opcodePong = 0xA;

  static const int finBit = 0x80;
  static const int rsv1Bit = 0x40;
  static const int maskBit = 0x80;
  static const int opcodeMask = 0x0F;
  static const int payloadLengthMask = 0x7F;

  static const int payloadLength16Bit = 126;
  static const int payloadLength64Bit = 127;
  static const int maxSingleBytePayloadLength = 125;
  static const int maxUint16 = 65535;

  static const int closeCodeNormal = 1000;
  static const int closeCodeMin = 1000;
  static const int closeCodeMax = 4999;

  static const int maskKeyLength = 4;
  static const int randomBytesLength = 16;

  static const String webSocketVersion = '13';
  static const String webSocketGuid = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';
  static const String webSocketExtension = 'permessage-deflate; client_max_window_bits';

  // DEFLATE trailer for decompression
  static const List<int> deflateTrailer = [0x00, 0x00, 0xFF, 0xFF];
}

/// Exception thrown when WebSocket operations fail.
class WebSocketException implements Exception {
  /// Creates a WebSocket exception.
  const WebSocketException(this.message, [this.details]);

  /// A description of the error.
  final String message;

  /// Additional error details.
  final Object? details;

  @override
  String toString() => 'WebSocketException: $message${details != null ? ' ($details)' : ''}';
}

/// A WebSocket implementation over HTTP/2 using the RFC 8441 extended CONNECT method.
///
/// This class provides WebSocket functionality over HTTP/2 connections,
/// supporting text and binary messages, compression (permessage-deflate),
/// and proper connection lifecycle management.
///
/// Example usage:
/// ```dart
/// final ws = await connectWebSocketOverHttp2(Uri.parse('wss://example.com'));
/// if (ws != null) {
///   ws.listen(
///     onData: (message) => print('Received: ${message.data}'),
///     onError: (error) => print('Error: $error'),
///     onDone: () => print('Connection closed'),
///   );
///   ws.add('Hello, WebSocket!');
/// }
/// ```
class Http2WebSocket {
  Http2WebSocket._(this._requestStream, this._subscription) {
    // Set up handler to process incoming messages
    _subscription
      ..onData(_handleIncomingMessage)
      ..onError(_controller.addError)
      ..onDone(() {
        if (!_closed) {
          _controller.close();
        }
      });

    // Send initial empty DATA to activate bidirectional stream (per RFC 8441)
    _requestStream.sendData(Uint8List(0));
  }

  final StreamController<WebSocketMessage> _controller =
      StreamController<WebSocketMessage>.broadcast();
  final ClientTransportStream _requestStream;
  final StreamSubscription<StreamMessage> _subscription;
  bool _closed = false;

  /// Stream of messages received from the WebSocket connection.
  ///
  /// Listen to this stream to receive both text and binary messages.
  /// Each message includes metadata about its type.
  Stream<WebSocketMessage> get stream => _controller.stream;

  /// Sends a text message over the WebSocket connection.
  ///
  /// The [message] will be encoded as UTF-8 and sent as a WebSocket text frame.
  ///
  /// Throws [StateError] if the connection is already closed.
  void add(String message) {
    _ensureNotClosed();
    final payload = utf8.encode(message);
    final frame = _buildFrame(payload, opcode: _WebSocketConstants.opcodeText);
    _requestStream.sendData(frame);
  }

  /// Sends binary data over the WebSocket connection.
  ///
  /// The [data] will be sent as-is in a WebSocket binary frame.
  ///
  /// Throws [StateError] if the connection is already closed.
  void addBinary(Uint8List data) {
    _ensureNotClosed();
    final frame = _buildFrame(data, opcode: _WebSocketConstants.opcodeBinary);
    _requestStream.sendData(frame);
  }

  /// Closes the WebSocket connection.
  ///
  /// Optionally sends a close frame with the specified [code] and [reason].
  /// The [code] must be between 1000 and 4999 inclusive, or it will be omitted.
  ///
  /// This method is idempotent - calling it multiple times has no additional effect.
  void close([int code = _WebSocketConstants.closeCodeNormal, String reason = '']) {
    if (_closed) {
      return;
    }
    _closed = true;

    final payload = BytesBuilder();
    if (code >= _WebSocketConstants.closeCodeMin && code <= _WebSocketConstants.closeCodeMax) {
      // Close payload: 2-byte status code (big-endian) + reason
      payload
        ..addByte((code >> 8) & 0xFF)
        ..addByte(code & 0xFF);
    }
    payload.add(utf8.encode(reason));

    final frame = _buildFrame(payload.toBytes(), opcode: _WebSocketConstants.opcodeClose);
    _requestStream.sendData(frame, endStream: true);
    _controller.close();
  }

  /// Ensures the connection is not closed before performing operations.
  void _ensureNotClosed() {
    if (_closed) {
      throw StateError('WebSocket connection is already closed');
    }
  }

  /// Builds a masked WebSocket frame according to RFC 6455.
  ///
  /// Client-side frames must be masked with a random 4-byte key.
  /// The frame format includes:
  /// - FIN bit (1) + opcode
  /// - Mask bit (1) + payload length
  /// - Extended payload length (if needed)
  /// - Masking key (4 bytes)
  /// - Masked payload data
  Uint8List _buildFrame(Uint8List payload, {required int opcode}) {
    final maskKey = _generateMaskKey();
    final maskedPayload = _maskPayload(payload, maskKey);

    final header = BytesBuilder()..addByte(_WebSocketConstants.finBit | opcode);

    final len = maskedPayload.length;
    if (len <= _WebSocketConstants.maxSingleBytePayloadLength) {
      header.addByte(_WebSocketConstants.maskBit | len);
    } else if (len <= _WebSocketConstants.maxUint16) {
      header
        ..addByte(_WebSocketConstants.maskBit | _WebSocketConstants.payloadLength16Bit)
        ..addByte((len >> 8) & 0xFF)
        ..addByte(len & 0xFF);
    } else {
      header.addByte(_WebSocketConstants.maskBit | _WebSocketConstants.payloadLength64Bit);
      final byteData = ByteData(8)..setUint64(0, len);
      header.add(Uint8List.view(byteData.buffer));
    }

    return (header
          ..add(maskKey)
          ..add(maskedPayload))
        .toBytes();
  }

  /// Generates a random 4-byte masking key for WebSocket frames.
  Uint8List _generateMaskKey() {
    return Uint8List.fromList(
      List.generate(_WebSocketConstants.maskKeyLength, (_) => Random().nextInt(256)),
    );
  }

  /// Masks payload data using XOR with the provided mask key.
  Uint8List _maskPayload(Uint8List payload, Uint8List maskKey) {
    final masked = Uint8List(payload.length);
    for (var i = 0; i < payload.length; i++) {
      masked[i] = payload[i] ^ maskKey[i % _WebSocketConstants.maskKeyLength];
    }
    return masked;
  }

  /// Handles incoming stream messages from the HTTP/2 connection.
  ///
  /// Processes data frames by parsing WebSocket frames and emitting messages.
  /// Additional headers after handshake are logged but ignored.
  void _handleIncomingMessage(StreamMessage message) {
    if (message is DataStreamMessage) {
      final frameBytes = message.bytes;
      if (frameBytes.isEmpty) {
        return;
      }

      final payload = _parseFrame(Uint8List.fromList(frameBytes));
      if (payload != null) {
        _controller.add(payload);
      }
    } else if (message is HeadersStreamMessage) {
      // RFC 8441 allows no additional headers after handshake, but handle gracefully
      if (message.headers.isNotEmpty) {
        print('Additional headers received: ${message.headers.length}');
      }
    }
  }

  /// Parses a WebSocket frame according to RFC 6455.
  ///
  /// Server-to-client frames are typically unmasked.
  /// Returns a [WebSocketMessage] for text/binary frames, or null for control frames.
  /// Automatically handles ping/pong, close frames, and decompression.
  WebSocketMessage? _parseFrame(Uint8List frame) {
    if (frame.length < 2) {
      return null;
    }

    final firstByte = frame[0];
    final opcode = firstByte & _WebSocketConstants.opcodeMask;
    final rsv1 = (firstByte & _WebSocketConstants.rsv1Bit) != 0; // Compression bit
    final maskLen = frame[1];
    final masked = (maskLen & _WebSocketConstants.maskBit) != 0;
    var payloadLen = maskLen & _WebSocketConstants.payloadLengthMask;
    var offset = 2;

    // Parse extended payload length
    if (payloadLen == _WebSocketConstants.payloadLength16Bit) {
      if (frame.length < 4) {
        return null;
      }
      payloadLen = (frame[2] << 8) | frame[3];
      offset = 4;
    } else if (payloadLen == _WebSocketConstants.payloadLength64Bit) {
      if (frame.length < 10) {
        return null;
      }
      final view = ByteData.sublistView(frame, 2, 10);
      payloadLen = view.getUint64(0);
      offset = 10;
    }

    Uint8List? maskKey;
    if (masked) {
      if (frame.length < offset + _WebSocketConstants.maskKeyLength) {
        return null;
      }
      maskKey = frame.sublist(offset, offset + _WebSocketConstants.maskKeyLength);
      offset += _WebSocketConstants.maskKeyLength;
    }

    if (frame.length < offset + payloadLen) {
      return null;
    }

    final payload = frame.sublist(offset, offset + payloadLen);
    var unmasked = Uint8List(payloadLen);

    if (masked && maskKey != null) {
      for (var i = 0; i < payloadLen; i++) {
        unmasked[i] = payload[i] ^ maskKey[i % _WebSocketConstants.maskKeyLength];
      }
    } else {
      // Copy payload directly (server frames are typically unmasked)
      unmasked.setRange(0, payloadLen, payload);
    }

    // Decompress if RSV1 bit is set (permessage-deflate extension)
    if (rsv1 &&
        (opcode == _WebSocketConstants.opcodeText || opcode == _WebSocketConstants.opcodeBinary)) {
      unmasked = _decompressPayload(unmasked);
    }

    // Process frame based on opcode
    return _processFrameByOpcode(opcode, unmasked);
  }

  /// Decompresses a payload using DEFLATE algorithm.
  ///
  /// Adds the required DEFLATE trailer and uses raw DEFLATE format
  /// (no zlib wrapper) as per permessage-deflate specification.
  Uint8List _decompressPayload(Uint8List compressed) {
    try {
      final withTrailer = BytesBuilder()
        ..add(compressed)
        ..add(_WebSocketConstants.deflateTrailer);

      final decompressed = ZLibDecoder(raw: true).convert(withTrailer.toBytes());
      return Uint8List.fromList(decompressed);
    } catch (e) {
      print('Decompression error: $e');
      rethrow;
    }
  }

  /// Processes a WebSocket frame based on its opcode.
  ///
  /// Returns appropriate [WebSocketMessage] for data frames,
  /// handles control frames (ping, pong, close), and returns null
  /// when no message should be emitted to the stream.
  WebSocketMessage? _processFrameByOpcode(int opcode, Uint8List payload) {
    switch (opcode) {
      case _WebSocketConstants.opcodeText:
        try {
          final text = utf8.decode(payload);
          return WebSocketMessage(type: WebSocketMessageType.text, data: text);
        } catch (e) {
          print('UTF-8 decode error: $e');
          return null;
        }

      case _WebSocketConstants.opcodeBinary:
        return WebSocketMessage(type: WebSocketMessageType.binary, data: payload);

      case _WebSocketConstants.opcodeClose:
        close();
        return null;

      case _WebSocketConstants.opcodePing:
        _sendPong(payload);
        return null;

      case _WebSocketConstants.opcodePong:
        // Pong frames are handled silently
        return null;

      default:
        print('Unknown opcode: 0x${opcode.toRadixString(16)}');
        return null;
    }
  }

  /// Sends a pong frame in response to a ping.
  void _sendPong(Uint8List payload) {
    if (_closed) {
      return;
    }
    final pong = _buildFrame(payload, opcode: _WebSocketConstants.opcodePong);
    _requestStream.sendData(pong);
  }

  /// Convenience method to listen to WebSocket messages.
  ///
  /// Provides a simpler API similar to the built-in WebSocket class.
  ///
  /// Example:
  /// ```dart
  /// ws.listen(
  ///   onData: (message) {
  ///     if (message.type == WebSocketMessageType.text) {
  ///       print('Text: ${message.asText}');
  ///     } else {
  ///       print('Binary: ${message.asBinary.length} bytes');
  ///     }
  ///   },
  ///   onError: (error) => print('Error: $error'),
  ///   onDone: () => print('Connection closed'),
  /// );
  /// ```
  void listen({
    void Function(WebSocketMessage)? onData,
    void Function(Object error, StackTrace stackTrace)? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

/// Computes the expected `sec-websocket-accept` header value per RFC 6455.
///
/// This combines the client's WebSocket key with the magic GUID and
/// returns the SHA-1 hash encoded in base64.
String _computeWebSocketAccept(String key) {
  final combined = key + _WebSocketConstants.webSocketGuid;
  final hash = sha1.convert(utf8.encode(combined));
  return base64Encode(hash.bytes);
}

/// Generates a random WebSocket key for the handshake.
///
/// Returns a base64-encoded string of 16 random bytes, as required by RFC 6455.
String _generateWebSocketKey() {
  final randomBytes = List<int>.generate(
    _WebSocketConstants.randomBytesLength,
    (_) => Random().nextInt(256),
  );
  return base64Encode(randomBytes);
}

/// Establishes a WebSocket connection over HTTP/2 using RFC 8441 extended CONNECT.
///
/// This function creates a WebSocket connection using the HTTP/2 protocol's
/// extended CONNECT method, as specified in RFC 8441. It performs the WebSocket
/// handshake and verifies the server's response.
///
/// The [uri] must use the `wss://` scheme for secure connections.
///
/// Returns a [Http2WebSocket] instance if the connection is successful,
/// or `null` if the connection or handshake fails.
///
/// Example:
/// ```dart
/// final uri = Uri.parse('wss://echo.websocket.org');
/// final ws = await connectWebSocketOverHttp2(uri);
/// if (ws != null) {
///   ws.add('Hello, WebSocket!');
///   ws.listen(
///     onData: (message) => print('Received: ${message.data}'),
///   );
/// }
/// ```
///
/// Throws [WebSocketException] if the connection fails or handshake is invalid.
Future<Http2WebSocket?> connectWebSocketOverHttp2(Uri uri) async {
  try {
    // Establish secure HTTP/2 connection
    final socket = await SecureSocket.connect(uri.host, uri.port, supportedProtocols: const ['h2']);

    final transport = ClientTransportConnection.viaSocket(socket);

    // Generate WebSocket key for handshake
    final wsKey = _generateWebSocketKey();

    // Build extended CONNECT request headers (RFC 8441)
    final requestHeaders = [
      Header.ascii(':method', 'CONNECT'),
      Header.ascii(':protocol', 'websocket'),
      Header.ascii(':scheme', uri.scheme),
      Header.ascii(':path', uri.path.isEmpty ? '/' : uri.path),
      Header.ascii(':authority', uri.host),
      Header.ascii('sec-websocket-version', _WebSocketConstants.webSocketVersion),
      Header.ascii('sec-websocket-key', wsKey),
      Header.ascii('sec-websocket-extensions', _WebSocketConstants.webSocketExtension),
    ];

    final requestStream = transport.makeRequest(requestHeaders);

    // Wait for handshake response with :status 200
    final completer = Completer<Http2WebSocket?>();
    late StreamSubscription<StreamMessage> subscription;

    subscription = requestStream.incomingMessages.listen(
      (message) {
        if (message is HeadersStreamMessage) {
          final headers = _parseHeaders(message.headers);
          final status = headers[':status'];

          if (status == '200') {
            _verifyHandshakeAndComplete(
              headers: headers,
              wsKey: wsKey,
              requestStream: requestStream,
              subscription: subscription,
              completer: completer,
            );
          } else {
            print('WebSocket handshake failed: :status = $status');
            subscription.cancel();
            completer.complete(null);
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        print('Stream error: $error\n$stackTrace');
        if (!completer.isCompleted) {
          completer.complete(null);
        }
        subscription.cancel();
      },
      onDone: () {
        if (!completer.isCompleted) {
          print('Stream closed before handshake completed');
          completer.complete(null);
        }
      },
    );

    final result = await completer.future;

    if (result == null) {
      await transport.finish();
    }
    return result;
  } catch (e, stackTrace) {
    print('WebSocket connection error: $e\n$stackTrace');
    return null;
  }
}

/// Parses HTTP/2 headers into a map.
Map<String, String> _parseHeaders(List<Header> headers) {
  final result = <String, String>{};
  for (final header in headers) {
    final name = utf8.decode(header.name);
    final value = utf8.decode(header.value);
    result[name] = value;
  }
  return result;
}

/// Verifies the WebSocket handshake and completes the connection.
void _verifyHandshakeAndComplete({
  required Map<String, String> headers,
  required String wsKey,
  required ClientTransportStream requestStream,
  required StreamSubscription<StreamMessage> subscription,
  required Completer<Http2WebSocket?> completer,
}) {
  final accept = headers['sec-websocket-accept'];

  // Note: Some servers may not include sec-websocket-accept header.
  // While RFC 6455 requires it, we can proceed without verification for compatibility.
  if (accept == null) {
    print('Warning: Missing sec-websocket-accept header, proceeding without verification');
    // Create the WebSocket instance without verification
    final ws = Http2WebSocket._(requestStream, subscription);
    completer.complete(ws);
    return;
  }

  final expectedAccept = _computeWebSocketAccept(wsKey);
  if (accept != expectedAccept) {
    print('Handshake failed: Invalid sec-websocket-accept');
    print('  Expected: $expectedAccept');
    print('  Received: $accept');
    subscription.cancel();
    completer.complete(null);
    return;
  }

  print('WebSocket handshake successful! sec-websocket-accept verified.');

  // Create the WebSocket instance
  final ws = Http2WebSocket._(requestStream, subscription);
  completer.complete(ws);
}
