import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:http2/http2.dart';
import 'package:crypto/crypto.dart'; // For SHA-1

Future<void> main() async {
  final uri = Uri.parse('https://51.75.87.132:4443');
  final ws = await connectWebSocketOverHttp2(uri);

  final ws2 = await connectWebSocketOverHttp2(uri);
  if (ws2 != null) {
    ws2.stream.listen((m) => print('ws2: $m'));
    ws2.add("ws2: Hello HTTP/2 WebSocket!");
  }

  await Future.delayed(Duration(seconds: 60));
  ws?.close();
    ws2?.close();
}


class Http2WebSocket {
  final StreamController<dynamic> _controller = StreamController<dynamic>.broadcast();
  final _requestStream; // The unnamed object from makeRequest()
  bool _closed = false;
  final StreamSubscription _subscription;

  Http2WebSocket._(this._requestStream, this._subscription) {
    // Set up handler to process incoming messages
    _subscription.onData((message) => _handleIncomingMessage(message as StreamMessage));
    _subscription.onError(_controller.addError);
    _subscription.onDone(() {
      if (!_closed) _controller.close();
    });
    
    // Send initial empty DATA to activate bidirectional stream (per RFC 8441)
    _requestStream.sendData(Uint8List(0), endStream: false);
  }

  Stream<dynamic> get stream => _controller.stream;

  /// Send a text message.
  void add(String message) {
    if (_closed) return;
    final payload = utf8.encode(message);
    final frame = _buildFrame(payload, opcode: 0x1); // Text
    _requestStream.sendData(frame, endStream: false);
  }

  /// Send binary data.
  void addBinary(Uint8List data) {
    if (_closed) return;
    final frame = _buildFrame(data, opcode: 0x2); // Binary
    _requestStream.sendData(frame, endStream: false);
  }

  /// Close the WebSocket.
  void close([int code = 1000, String reason = '']) {
    if (_closed) return;
    _closed = true;

    final payload = BytesBuilder();
    if (code >= 1000 && code <= 4999) {
      // Close payload: 2-byte status code (big-endian) + reason
      payload.addByte((code >> 8) & 0xFF);
      payload.addByte(code & 0xFF);
    }
    payload.add(utf8.encode(reason));

    final frame = _buildFrame(payload.toBytes(), opcode: 0x8); // Close
    _requestStream.sendData(frame, endStream: true);
    _controller.close();
  }

  /// Build masked WebSocket frame (client-side, per RFC 6455).
  Uint8List _buildFrame(Uint8List payload, {required int opcode}) {
    final maskKey = Uint8List.fromList(List.generate(4, (_) => Random().nextInt(256)));
    final maskedPayload = Uint8List(payload.length);
    for (int i = 0; i < payload.length; i++) {
      maskedPayload[i] = payload[i] ^ maskKey[i % 4];
    }

    final header = BytesBuilder();
    header.addByte(0x80 | opcode); // FIN=1 + opcode

    final len = maskedPayload.length;
    if (len <= 125) {
      header.addByte(0x80 | len);
    } else if (len <= 65535) {
      header.addByte(0x80 | 126);
      header.addByte((len >> 8) & 0xFF);
      header.addByte(len & 0xFF);
    } else {
      header.addByte(0x80 | 127);
      final byteData = ByteData(8)..setUint64(0, len, Endian.big);
      header.add(Uint8List.view(byteData.buffer));
    }

    header.add(maskKey);
    header.add(maskedPayload);
    return header.toBytes();
  }

  /// Handle incoming StreamMessage.
  void _handleIncomingMessage(StreamMessage message) {
    if (message is DataStreamMessage) {
      final frameBytes = message.bytes;
      if (frameBytes.isEmpty) return;

      final payload = _parseFrame(Uint8List.fromList(frameBytes));
      if (payload != null) {
        _controller.add(payload);
      }
    } else if (message is HeadersStreamMessage) {
      // Ignore additional headers after handshake (RFC 8441 allows none, but handle gracefully)
      print('Additional headers received: ${message.headers.length}');
    }
  }

  /// Parse WebSocket frame (server-side frames are unmasked).
  dynamic _parseFrame(Uint8List frame) {
  if (frame.length < 2) return null;

  final firstByte = frame[0];
  final opcode = firstByte & 0x0F;
  final rsv1 = (firstByte & 0x40) != 0; // Compression bit
  final maskLen = frame[1];
  final masked = (maskLen & 0x80) != 0;
  var payloadLen = maskLen & 0x7F;
  var offset = 2;

  // Parse extended payload length
  if (payloadLen == 126) {
    if (frame.length < 4) return null;
    payloadLen = (frame[2] << 8) | frame[3];
    offset = 4;
  } else if (payloadLen == 127) {
    if (frame.length < 10) return null;
    final view = ByteData.sublistView(frame, 2, 10);
    payloadLen = view.getUint64(0, Endian.big);
    offset = 10;
  }

  Uint8List? maskKey;
  if (masked) {
    if (frame.length < offset + 4) return null;
    maskKey = frame.sublist(offset, offset + 4);
    offset += 4;
  }

  if (frame.length < offset + payloadLen) return null;

  final payload = frame.sublist(offset, offset + payloadLen);
  var unmasked = Uint8List(payloadLen);

  if (masked && maskKey != null) {
    for (int i = 0; i < payloadLen; i++) {
      unmasked[i] = payload[i] ^ maskKey[i % 4];
    }
  } else {
    // Copy payload directly
    unmasked.setRange(0, payloadLen, payload);
  }

  // Decompress if RSV1 bit is set (permessage-deflate)
  if (rsv1 && (opcode == 0x1 || opcode == 0x2)) {
    try {
      // Add DEFLATE trailer (0x00 0x00 0xFF 0xFF) for decompression
      final compressed = BytesBuilder();
      compressed.add(unmasked);
      compressed.add([0x00, 0x00, 0xFF, 0xFF]);
      
      // Decompress using ZLibDecoder with raw DEFLATE (no zlib wrapper)
      final decompressed = ZLibDecoder(raw: true).convert(compressed.toBytes());
      unmasked = Uint8List.fromList(decompressed);
    } catch (e) {
      print('Decompression error: $e');
      return null;
    }
  }

  switch (opcode) {
    case 0x1: // Text
      return utf8.decode(unmasked);
    case 0x2: // Binary
      return unmasked;
    case 0x8: // Close
      close();
      return null;
    case 0x9: // Ping
      final pong = _buildFrame(unmasked, opcode: 0xA);
      _requestStream.sendData(pong, endStream: false);
      return null;
    case 0xA: // Pong
      return null;
    default:
      return null;
  }
}

  /// Convenience listen method (like built-in WebSocket).
  void listen({
    void Function(dynamic)? onData,
    Function(dynamic)? onError,
    void Function()? onDone,
  }) {
    stream.listen(onData, onError: onError, onDone: onDone);
  }
}

Future<Http2WebSocket?> connectWebSocketOverHttp2(Uri uri) async {
  try {
    final socket = await SecureSocket.connect(
      uri.host,
      uri.port,
      supportedProtocols: const ['h2'],
    );

    final transport = ClientTransportConnection.viaSocket(socket);

    // Generate WS key (base64 of 16 random bytes).
    final randomBytes = List<int>.generate(16, (_) => Random().nextInt(256));
    final wsKey = base64Encode(randomBytes);

    // Build CONNECT request for RFC 8441.
    final requestHeaders = [
      Header.ascii(':method', 'CONNECT'),
      Header.ascii(':protocol', 'websocket'),
      Header.ascii(':scheme', uri.scheme),
      Header.ascii(':path', uri.path.isEmpty ? '/' : uri.path),
      Header.ascii(':authority', uri.host),
      Header.ascii('sec-websocket-version', '13'),
      Header.ascii('sec-websocket-key', wsKey),
      Header.ascii('sec-websocket-extensions', 'permessage-deflate; client_max_window_bits'),
    ];

    final requestStream = transport.makeRequest(requestHeaders, endStream: false);

    // Wait for handshake response (headers with :status 200).
    final completer = Completer<Http2WebSocket?>();
    late StreamSubscription<StreamMessage> subscription;

    subscription = requestStream.incomingMessages.listen(
      (message) {
        if (message is HeadersStreamMessage) {
          final headers = <String, String>{};
          for (final header in message.headers) {
            final name = utf8.decode(header.name);
            final value = utf8.decode(header.value);
            headers[name] = value;
          }

          final status = headers[':status'];
          if (status == '200') {
            print('Handshake successful!');

            // Create the WebSocket using the existing subscription
            final ws = Http2WebSocket._(requestStream, subscription);
            
            // Now set up the message handler on the subscription
            completer.complete(ws);
          } else {
            print('Handshake failed: :status = $status');
            subscription.cancel();
            completer.complete(null);
          }
        }
      },
      onError: (error) {
        print('Stream error: $error');
        completer.complete(null);
        subscription.cancel();
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    );

    final result = await completer.future;

    if (result == null) {
      transport.finish();
    }
    return result;
  } catch (e) {
    print('Connection error: $e');
    return null;
  }
}