// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http2/http2.dart';
import 'package:ion_token_analytics/src/http2_client/http2_connection.dart';
import 'package:ion_token_analytics/src/http2_client/http2_exceptions.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_web_socket_message.dart';
import 'package:ion_token_analytics/src/http2_client/web_socket/web_socket_constants.dart';
import 'package:ion_token_analytics/src/http2_client/web_socket/web_socket_frame_builder.dart';
import 'package:ion_token_analytics/src/http2_client/web_socket/web_socket_frame_parser.dart';

/// A WebSocket implementation over HTTP/2 using the RFC 8441 extended CONNECT method.
///
/// Delegates frame parsing to [WebSocketFrameParser] and frame building
/// to [WebSocketFrameBuilder], keeping this class focused on connection
/// lifecycle and message routing.
class Http2WebSocket {
  Http2WebSocket._(this._requestStream, this._subscription) {
    _subscription
      ..onData(_handleIncomingMessage)
      ..onError(_controller.addError)
      ..onDone(() {
        if (!_closed) {
          _controller.close();
        }
      });

    _requestStream.sendData(Uint8List(0));
  }

  static Future<Http2WebSocket> fromHttp2Connection(
    Http2Connection connection, {
    String path = '/',
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final wsKey = _generateWebSocketKey();

      final uri = Uri(
        path: path.startsWith('/') ? path : '/$path',
        queryParameters: queryParameters,
      );
      final fullPath = uri.toString();

      final requestHeaders = [
        Header.ascii(':method', 'CONNECT'),
        Header.ascii(':protocol', 'websocket'),
        Header.ascii(':scheme', connection.scheme),
        Header.ascii(':path', fullPath),
        Header.ascii(':authority', connection.host),
        Header.ascii('sec-websocket-version', WebSocketConstants.webSocketVersion),
        Header.ascii('sec-websocket-key', wsKey),
        Header.ascii('sec-websocket-extensions', WebSocketConstants.webSocketExtension),
      ];

      if (headers != null) {
        for (final entry in headers.entries) {
          requestHeaders.add(Header.ascii(entry.key, entry.value));
        }
      }

      final requestStream = connection.transport!.makeRequest(requestHeaders);

      final completer = Completer<Http2WebSocket>();
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
              subscription.cancel();
              if (!completer.isCompleted) {
                completer.completeError(
                  WebSocketHandshakeStatusException(status ?? 'unknown'),
                );
              }
            }
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          subscription.cancel();
          if (!completer.isCompleted) {
            completer.completeError(
              WebSocketStreamException('$error\n$stackTrace'),
              stackTrace,
            );
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.completeError(const WebSocketHandshakeStreamClosedException());
          }
        },
      );

      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          subscription.cancel();
          throw WebSocketHandshakeException(
            'Handshake timeout after ${timeout.inSeconds}s',
          );
        },
      );
    } catch (e, stackTrace) {
      if (e is Http2ClientException) rethrow;
      throw WebSocketHandshakeException('$e\n$stackTrace');
    }
  }

  static String _generateWebSocketKey() {
    final randomBytes = List<int>.generate(
      WebSocketConstants.randomBytesLength,
      (_) => Random().nextInt(256),
    );
    return base64Encode(randomBytes);
  }

  static Map<String, String> _parseHeaders(List<Header> headers) {
    final result = <String, String>{};
    for (final header in headers) {
      result[utf8.decode(header.name)] = utf8.decode(header.value);
    }
    return result;
  }

  static String _computeWebSocketAccept(String key) {
    final combined = key + WebSocketConstants.webSocketGuid;
    final hash = sha1.convert(utf8.encode(combined));
    return base64Encode(hash.bytes);
  }

  static void _verifyHandshakeAndComplete({
    required Map<String, String> headers,
    required String wsKey,
    required ClientTransportStream requestStream,
    required StreamSubscription<StreamMessage> subscription,
    required Completer<Http2WebSocket> completer,
  }) {
    final accept = headers['sec-websocket-accept'];

    if (accept == null) {
      completer.complete(Http2WebSocket._(requestStream, subscription));
      return;
    }

    final expectedAccept = _computeWebSocketAccept(wsKey);
    if (accept != expectedAccept) {
      subscription.cancel();
      completer.completeError(
        WebSocketHandshakeAcceptException(expectedAccept, accept),
      );
      return;
    }

    completer.complete(Http2WebSocket._(requestStream, subscription));
  }

  final StreamController<Http2WebSocketMessage> _controller =
      StreamController<Http2WebSocketMessage>.broadcast();
  final ClientTransportStream _requestStream;
  final StreamSubscription<StreamMessage> _subscription;
  final WebSocketFrameParser _frameParser = WebSocketFrameParser();
  final WebSocketFrameBuilder _frameBuilder = WebSocketFrameBuilder();
  bool _closed = false;

  Stream<Http2WebSocketMessage> get stream => _controller.stream;

  void add(String message) {
    _ensureNotClosed();
    final payload = utf8.encode(message);
    final frame = _frameBuilder.build(
      Uint8List.fromList(payload),
      opcode: WebSocketConstants.opcodeText,
    );
    _requestStream.sendData(frame);
  }

  void addBinary(Uint8List data) {
    _ensureNotClosed();
    final frame = _frameBuilder.build(data, opcode: WebSocketConstants.opcodeBinary);
    _requestStream.sendData(frame);
  }

  void close([int code = WebSocketConstants.closeCodeNormal, String reason = '']) {
    if (_closed) return;
    _closed = true;

    _frameParser.reset();

    final payload = BytesBuilder();
    if (code >= WebSocketConstants.closeCodeMin && code <= WebSocketConstants.closeCodeMax) {
      payload
        ..addByte((code >> 8) & 0xFF)
        ..addByte(code & 0xFF);
    }
    payload.add(utf8.encode(reason));

    final frame = _frameBuilder.build(
      payload.toBytes(),
      opcode: WebSocketConstants.opcodeClose,
    );
    _requestStream.sendData(frame, endStream: true);
    _subscription.cancel();
    _controller.close();
  }

  void _ensureNotClosed() {
    if (_closed) throw const WebSocketClosedException();
  }

  void _handleIncomingMessage(StreamMessage message) {
    if (message is DataStreamMessage) {
      final frameBytes = message.bytes;
      if (frameBytes.isEmpty) return;

      try {
        final result = _frameParser.parse(
          Uint8List.fromList(frameBytes),
          onPing: _sendPong,
          onClose: close,
        );
        if (result != null) _controller.add(result);
      } catch (e, stackTrace) {
        _controller.addError(e, stackTrace);
      }
    }
  }

  void _sendPong(Uint8List payload) {
    if (_closed) return;
    final pong = _frameBuilder.build(payload, opcode: WebSocketConstants.opcodePong);
    _requestStream.sendData(pong);
  }
}
