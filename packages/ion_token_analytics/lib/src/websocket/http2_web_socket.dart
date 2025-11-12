import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http2/http2.dart';
import 'package:ion_token_analytics/src/websocket/http2_connection.dart';
import 'package:ion_token_analytics/src/websocket/web_socket_message.dart';

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

/// A WebSocket implementation over HTTP/2 using the RFC 8441 extended CONNECT method.
///
/// This class provides WebSocket functionality over HTTP/2 connections,
/// supporting text and binary messages, compression (permessage-deflate),
/// and proper connection lifecycle management.
///
/// Example usage:
/// ```dart
/// // Using Http2Connection (recommended for multiple connections):
/// final connection = await Http2Connection.connect('example.com');
/// final ws1 = await connection.websocket(path: '/stream1');
/// final ws2 = await connection.websocket(path: '/stream2');
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

  /// Creates a WebSocket connection over HTTP/2 using an existing [Http2Connection].
  ///
  /// The [connection] must be an active HTTP/2 connection.
  /// The [path] specifies the WebSocket endpoint (defaults to '/').
  /// Additional [headers] can be provided for custom values.
  ///
  /// Returns a [Http2WebSocket] instance if successful, or `null` if the handshake fails.
  ///
  /// Example:
  /// ```dart
  /// final connection = await Http2Connection.connect('example.com');
  /// final ws = await Http2WebSocket.fromHttp2Connection(
  ///   connection,
  ///   path: '/api/stream',
  ///   headers: {'authorization': 'Bearer token'},
  /// );
  /// ```
  static Future<Http2WebSocket?> fromHttp2Connection(
    Http2Connection connection, {
    String path = '/',
    Map<String, String>? headers,
  }) async {
    try {
      final wsKey = _generateWebSocketKey();

      // Build extended CONNECT request headers (RFC 8441)
      final requestHeaders = [
        Header.ascii(':method', 'CONNECT'),
        Header.ascii(':protocol', 'websocket'),
        Header.ascii(':scheme', connection.scheme),
        Header.ascii(':path', path.isEmpty ? '/' : path),
        Header.ascii(':authority', connection.host),
        Header.ascii('sec-websocket-version', _WebSocketConstants.webSocketVersion),
        Header.ascii('sec-websocket-key', wsKey),
        Header.ascii('sec-websocket-extensions', _WebSocketConstants.webSocketExtension),
      ];

      // Add custom headers if provided
      if (headers != null) {
        for (final entry in headers.entries) {
          requestHeaders.add(Header.ascii(entry.key, entry.value));
        }
      }

      final requestStream = connection.transport.makeRequest(requestHeaders);

      // Wait for handshake response with :status 200
      final completer = Completer<Http2WebSocket?>();
      late StreamSubscription<StreamMessage> subscription;

      subscription = requestStream.incomingMessages.listen(
        (StreamMessage message) {
          if (message is HeadersStreamMessage) {
            final parsedHeaders = _parseHeaders(message.headers);
            final status = parsedHeaders[':status'];

            if (status == '200') {
              _verifyHandshakeAndComplete(
                headers: parsedHeaders,
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

      return await completer.future;
    } catch (e, stackTrace) {
      print('WebSocket creation error: $e\n$stackTrace');
      return null;
    }
  }

  /// Generates a random WebSocket key for the handshake.
  ///
  /// Returns a base64-encoded string of 16 random bytes, as required by RFC 6455.
  static String _generateWebSocketKey() {
    final randomBytes = List<int>.generate(
      _WebSocketConstants.randomBytesLength,
      (_) => Random().nextInt(256),
    );
    return base64Encode(randomBytes);
  }

  /// Parses HTTP/2 headers into a map.
  ///
  /// Converts the list of HTTP/2 [Header] objects into a map where both keys
  /// and values are UTF-8 decoded strings.
  static Map<String, String> _parseHeaders(List<Header> headers) {
    final result = <String, String>{};
    for (final header in headers) {
      final name = utf8.decode(header.name);
      final value = utf8.decode(header.value);
      result[name] = value;
    }
    return result;
  }

  /// Computes the expected `sec-websocket-accept` header value per RFC 6455.
  ///
  /// This combines the client's WebSocket [key] with the magic GUID and
  /// returns the SHA-1 hash encoded in base64.
  static String _computeWebSocketAccept(String key) {
    final combined = key + _WebSocketConstants.webSocketGuid;
    final hash = sha1.convert(utf8.encode(combined));
    return base64Encode(hash.bytes);
  }

  /// Verifies the WebSocket handshake and completes the connection.
  ///
  /// Checks the `sec-websocket-accept` header from the server against the expected
  /// value computed from [wsKey]. If verification succeeds or the header is missing
  /// (for compatibility), creates an [Http2WebSocket] instance and completes the
  /// [completer] with it. Otherwise, cancels the [subscription] and completes with null.
  static void _verifyHandshakeAndComplete({
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
    _subscription.cancel();
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
  /// Takes the [payload] data and [opcode] to construct a complete WebSocket frame.
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
  ///
  /// Applies XOR operation between each byte in [payload] and the corresponding
  /// byte from [maskKey] (cycling through the 4-byte key as needed).
  Uint8List _maskPayload(Uint8List payload, Uint8List maskKey) {
    final masked = Uint8List(payload.length);
    for (var i = 0; i < payload.length; i++) {
      masked[i] = payload[i] ^ maskKey[i % _WebSocketConstants.maskKeyLength];
    }
    return masked;
  }

  /// Handles incoming stream messages from the HTTP/2 connection.
  ///
  /// Processes data frames by parsing WebSocket frames and emitting messages
  /// to the controller stream. Additional headers after handshake are logged
  /// but ignored. The [message] can be either a [DataStreamMessage] containing
  /// WebSocket frame data or a [HeadersStreamMessage].
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
  /// Takes the raw [frame] bytes and extracts the payload data, handling masking,
  /// extended length encoding, and compression. Server-to-client frames are typically
  /// unmasked. Returns a [WebSocketMessage] for text/binary frames, or null for
  /// control frames. Automatically handles ping/pong, close frames, and decompression.
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
