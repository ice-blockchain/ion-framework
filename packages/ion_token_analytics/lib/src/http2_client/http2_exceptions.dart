// SPDX-License-Identifier: ice License 1.0

/// Base exception class for all HTTP/2 client-related errors.
sealed class Http2ClientException implements Exception {
  const Http2ClientException(this.message);

  /// The error message describing what went wrong.
  final String message;
}

/// Exception thrown when establishing an HTTP/2 connection fails.
///
/// This typically occurs when:
/// - The server is unreachable
/// - Network connectivity issues
/// - TLS/SSL handshake failures
/// - HTTP/2 negotiation failures
class Http2ConnectionException extends Http2ClientException {
  const Http2ConnectionException(String host, int port, dynamic error)
    : super('Failed to establish HTTP/2 connection to $host:$port: $error');
}

/// Exception thrown when the WebSocket handshake fails with a non-200 status code.
class WebSocketHandshakeStatusException extends Http2ClientException {
  const WebSocketHandshakeStatusException(String statusCode)
    : super('Server returned non-200 status code: $statusCode');
}

/// Exception thrown when sec-websocket-accept header validation fails.
class WebSocketHandshakeAcceptException extends Http2ClientException {
  const WebSocketHandshakeAcceptException(String expected, String received)
    : super('Invalid sec-websocket-accept header (expected: $expected, received: $received)');
}

/// Exception thrown when the WebSocket stream closes before handshake completion.
class WebSocketHandshakeStreamClosedException extends Http2ClientException {
  const WebSocketHandshakeStreamClosedException()
    : super('Stream closed before handshake completed');
}

/// Exception thrown when WebSocket creation fails for other reasons.
class WebSocketHandshakeException extends Http2ClientException {
  const WebSocketHandshakeException(dynamic error)
    : super('Failed to create WebSocket connection: $error');
}

/// Exception thrown when a WebSocket frame is too short.
class WebSocketFrameTooShortException extends Http2ClientException {
  const WebSocketFrameTooShortException() : super('Frame too short: minimum 2 bytes required');
}

/// Exception thrown when a 16-bit length frame is incomplete.
class WebSocketFrame16BitLengthException extends Http2ClientException {
  const WebSocketFrame16BitLengthException() : super('Incomplete frame: expected 16-bit length');
}

/// Exception thrown when a 64-bit length frame is incomplete.
class WebSocketFrame64BitLengthException extends Http2ClientException {
  const WebSocketFrame64BitLengthException() : super('Incomplete frame: expected 64-bit length');
}

/// Exception thrown when a frame is missing the mask key.
class WebSocketFrameMissingMaskException extends Http2ClientException {
  const WebSocketFrameMissingMaskException() : super('Incomplete frame: missing mask key');
}

/// Exception thrown when frame payload length doesn't match.
class WebSocketFramePayloadMismatchException extends Http2ClientException {
  const WebSocketFramePayloadMismatchException(int expected, int actual)
    : super(
        'Incomplete frame: payload length mismatch (expected $expected bytes, got $actual bytes)',
      );
}

/// Exception thrown when an unknown or unsupported opcode is received.
class WebSocketFrameUnsupportedOpcodeException extends Http2ClientException {
  WebSocketFrameUnsupportedOpcodeException(int opcode)
    : super('Unknown or unsupported opcode: 0x${opcode.toRadixString(16)}');
}

/// Exception thrown when an operation is attempted on a closed connection.
///
/// This occurs when trying to send data or perform operations on a
/// WebSocket connection that has already been closed.
class WebSocketClosedException extends Http2ClientException {
  const WebSocketClosedException()
    : super('Cannot perform operation on a closed WebSocket connection');
}

/// Exception thrown when stream operations fail during WebSocket communication.
///
/// This can occur when:
/// - The underlying HTTP/2 stream encounters an error
/// - Stream is terminated unexpectedly
/// - Data transmission fails
class WebSocketStreamException extends Http2ClientException {
  const WebSocketStreamException(dynamic error)
    : super('Stream error during WebSocket handshake: $error');
}

/// Exception thrown when UTF-8 decoding of text messages fails.
///
/// This occurs when a text frame contains invalid UTF-8 encoded data.
class WebSocketDecodingException extends Http2ClientException {
  const WebSocketDecodingException(dynamic error)
    : super('Failed to decode text message as UTF-8: $error');
}

/// Exception thrown when decompression of compressed messages fails.
///
/// This occurs when permessage-deflate extension is used and
/// the compressed data cannot be decompressed properly.
class WebSocketDecompressionException extends Http2ClientException {
  const WebSocketDecompressionException(dynamic error)
    : super('Failed to decompress WebSocket message: $error');
}

/// Exception thrown when an operation is attempted on a disposed Http2Client.
///
/// This occurs when trying to create a subscription or make a request
/// on a client that has already been disposed (e.g., due to provider rebuild
/// or app lifecycle changes).
///
/// When this exception is caught, callers should:
/// - Stop attempting reconnection
/// - Close any associated streams to allow providers to restart
/// - Create a new client instance if needed
class Http2ClientDisposedException extends Http2ClientException {
  const Http2ClientDisposedException() : super('Cannot perform operation on disposed Http2Client');
}

/// Exception thrown when the HTTP/2 connection has become stale.
///
/// This typically occurs when:
/// - The app was backgrounded and the OS closed the socket
/// - The network connection was interrupted
/// - A SocketException with errno 9 "Bad file descriptor" was received
/// - An HTTP/2 GOAWAY frame with error code 10 was received
///
/// When this exception is caught, callers should:
/// 1. Call `forceDisconnect()` on the client to clean up the stale connection
/// 2. Retry the operation after a delay (with exponential backoff)
class Http2StaleConnectionException extends Http2ClientException {
  const Http2StaleConnectionException(this.originalError)
    : super('HTTP/2 connection is stale (socket closed by OS or network interruption)');

  /// The original error that indicated the connection was stale.
  final Object originalError;

  /// Checks if an error indicates a stale connection.
  ///
  /// Returns true if the error is a SocketException with errno 9 (Bad file descriptor)
  /// or an HTTP/2 connection error with errorCode 10 (ENHANCE_YOUR_CALM / connection forcefully terminated).
  static bool isStaleConnectionError(Object error) {
    final errorString = error.toString();

    // Check for "Bad file descriptor" (errno = 9)
    if (errorString.contains('Bad file descriptor') || errorString.contains('errno = 9')) {
      return true;
    }

    // Check for HTTP/2 GOAWAY with errorCode 10
    if (errorString.contains('forcefully terminated') || errorString.contains('errorCode: 10')) {
      return true;
    }

    return false;
  }
}
