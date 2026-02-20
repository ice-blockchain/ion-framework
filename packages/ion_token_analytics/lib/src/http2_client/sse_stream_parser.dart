// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';

import 'package:http2/http2.dart';

/// Parses raw HTTP/2 data frames into Server-Sent Events.
///
/// Handles buffer management, `data:` line extraction, keepalive filtering,
/// and JSON decoding. Independently testable from the HTTP/2 connection.
class SseStreamParser<T> {
  static const String _keepalivePing = 'ping';
  static const String _keepalivePong = 'pong';

  /// Transforms a raw HTTP/2 message stream into a stream of parsed SSE events.
  ///
  /// The [messageStream] should come from `TransportStream.incomingMessages`.
  /// Header messages with non-200 status codes cause an error on the output stream.
  Stream<T> parse(Stream<StreamMessage> messageStream) {
    final controller = StreamController<T>.broadcast();
    var buffer = '';

    final subscription = messageStream.listen(
      (message) {
        if (controller.isClosed) return;

        if (message is DataStreamMessage) {
          final chunk = utf8.decode(message.bytes);
          buffer += chunk;

          while (buffer.contains('\n\n')) {
            final index = buffer.indexOf('\n\n');
            final eventString = buffer.substring(0, index);
            buffer = buffer.substring(index + 2);

            _processEvent(eventString, controller);
          }
        } else if (message is HeadersStreamMessage) {
          final headers = _parseHeaders(message.headers);
          final status = headers[':status'];
          if (status != null && status != '200') {
            controller.addError(
              Exception('SSE connection failed with status $status'),
            );
          }
        }
      },
      onError: controller.addError,
      onDone: () {
        if (!controller.isClosed) {
          controller.close();
        }
      },
    );

    controller.onCancel = subscription.cancel;

    return controller.stream;
  }

  void _processEvent(String eventString, StreamController<T> controller) {
    if (controller.isClosed) return;

    final lines = eventString.split('\n');
    String? data;

    for (final line in lines) {
      if (line.startsWith('data:')) {
        final lineData = line.substring(5).trim();
        data = data == null ? lineData : '$data\n$lineData';
      }
    }

    if (data == null) return;

    if (T == String) {
      controller.add(data as T);
      return;
    }

    final trimmed = data.trim();
    if (trimmed == _keepalivePing || trimmed == _keepalivePong) {
      return;
    }

    try {
      final parsed = jsonDecode(data);
      controller.add(parsed as T);
    } catch (e) {
      controller.addError(e);
    }
  }

  Map<String, String> _parseHeaders(List<Header> headers) {
    final result = <String, String>{};
    for (final header in headers) {
      result[utf8.decode(header.name)] = utf8.decode(header.value);
    }
    return result;
  }
}
