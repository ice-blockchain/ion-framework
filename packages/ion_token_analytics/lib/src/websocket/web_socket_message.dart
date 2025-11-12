import 'dart:typed_data';

/// Represents the type of message received from a WebSocket connection.
enum WebSocketMessageType {
  /// Text message encoded as UTF-8.
  text,

  /// Binary message with raw bytes.
  binary,
}

/// A message received from a WebSocket connection.
class WebSocketMessage {
  /// Creates a WebSocket message.
  const WebSocketMessage({required this.type, required this.data});

  /// The type of the message (text or binary).
  final WebSocketMessageType type;

  /// The message data. For text messages, this is a [String].
  /// For binary messages, this is a [Uint8List].
  final Object data;

  /// Returns the data as a [String] if this is a text message.
  String get asText {
    if (type != WebSocketMessageType.text) {
      throw StateError('Cannot convert binary message to text');
    }
    return data as String;
  }

  /// Returns the data as [Uint8List] if this is a binary message.
  Uint8List get asBinary {
    if (type != WebSocketMessageType.binary) {
      throw StateError('Cannot convert text message to binary');
    }
    return data as Uint8List;
  }
}
