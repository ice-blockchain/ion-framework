// SPDX-License-Identifier: ice License 1.0

/// Base exception class for all WebSocket-related errors.
sealed class WebSocketException implements Exception {
  const WebSocketException(this.code, this.message);

  /// The error code.
  final int code;

  /// The error message describing what went wrong.
  final String message;

  @override
  String toString() => 'WebSocketException(code: $code, message: $message)';
}

/// Exception thrown when establishing an HTTP/2 connection fails.
///
/// This typically occurs when:
/// - The server is unreachable
/// - Network connectivity issues
/// - TLS/SSL handshake failures
/// - HTTP/2 negotiation failures
class Http2ConnectionException extends WebSocketException {
  const Http2ConnectionException(String host, int port, dynamic error)
    : super(30000, 'Failed to establish HTTP/2 connection to $host:$port: $error');
}

/// Exception thrown when the WebSocket handshake fails with a non-200 status code.
class WebSocketHandshakeStatusException extends WebSocketException {
  const WebSocketHandshakeStatusException(String statusCode)
    : super(30001, 'Server returned non-200 status code: $statusCode');
}

/// Exception thrown when sec-websocket-accept header validation fails.
class WebSocketHandshakeAcceptException extends WebSocketException {
  const WebSocketHandshakeAcceptException(String expected, String received)
    : super(
        30002,
        'Invalid sec-websocket-accept header (expected: $expected, received: $received)',
      );
}

/// Exception thrown when the WebSocket stream closes before handshake completion.
class WebSocketHandshakeStreamClosedException extends WebSocketException {
  const WebSocketHandshakeStreamClosedException()
    : super(30003, 'Stream closed before handshake completed');
}

/// Exception thrown when WebSocket creation fails for other reasons.
class WebSocketHandshakeException extends WebSocketException {
  const WebSocketHandshakeException(dynamic error)
    : super(30004, 'Failed to create WebSocket connection: $error');
}

/// Exception thrown when a WebSocket frame is too short.
class WebSocketFrameTooShortException extends WebSocketException {
  const WebSocketFrameTooShortException()
    : super(30005, 'Frame too short: minimum 2 bytes required');
}

/// Exception thrown when a 16-bit length frame is incomplete.
class WebSocketFrame16BitLengthException extends WebSocketException {
  const WebSocketFrame16BitLengthException()
    : super(30006, 'Incomplete frame: expected 16-bit length');
}

/// Exception thrown when a 64-bit length frame is incomplete.
class WebSocketFrame64BitLengthException extends WebSocketException {
  const WebSocketFrame64BitLengthException()
    : super(30007, 'Incomplete frame: expected 64-bit length');
}

/// Exception thrown when a frame is missing the mask key.
class WebSocketFrameMissingMaskException extends WebSocketException {
  const WebSocketFrameMissingMaskException() : super(30008, 'Incomplete frame: missing mask key');
}

/// Exception thrown when frame payload length doesn't match.
class WebSocketFramePayloadMismatchException extends WebSocketException {
  const WebSocketFramePayloadMismatchException(int expected, int actual)
    : super(
        30009,
        'Incomplete frame: payload length mismatch (expected $expected bytes, got $actual bytes)',
      );
}

/// Exception thrown when an unknown or unsupported opcode is received.
class WebSocketFrameUnsupportedOpcodeException extends WebSocketException {
  WebSocketFrameUnsupportedOpcodeException(int opcode)
    : super(30010, 'Unknown or unsupported opcode: 0x${opcode.toRadixString(16)}');
}

/// Exception thrown when an operation is attempted on a closed connection.
///
/// This occurs when trying to send data or perform operations on a
/// WebSocket connection that has already been closed.
class WebSocketClosedException extends WebSocketException {
  const WebSocketClosedException()
    : super(30011, 'Cannot perform operation on a closed WebSocket connection');
}

/// Exception thrown when stream operations fail during WebSocket communication.
///
/// This can occur when:
/// - The underlying HTTP/2 stream encounters an error
/// - Stream is terminated unexpectedly
/// - Data transmission fails
class WebSocketStreamException extends WebSocketException {
  const WebSocketStreamException(dynamic error)
    : super(30012, 'Stream error during WebSocket handshake: $error');
}

/// Exception thrown when UTF-8 decoding of text messages fails.
///
/// This occurs when a text frame contains invalid UTF-8 encoded data.
class WebSocketDecodingException extends WebSocketException {
  const WebSocketDecodingException(dynamic error)
    : super(30013, 'Failed to decode text message as UTF-8: $error');
}

/// Exception thrown when decompression of compressed messages fails.
///
/// This occurs when permessage-deflate extension is used and
/// the compressed data cannot be decompressed properly.
class WebSocketDecompressionException extends WebSocketException {
  const WebSocketDecompressionException(dynamic error)
    : super(30014, 'Failed to decompress WebSocket message: $error');
}
