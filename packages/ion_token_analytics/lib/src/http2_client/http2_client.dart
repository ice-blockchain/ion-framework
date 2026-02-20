// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http2/http2.dart';
import 'package:ion_token_analytics/src/core/logger.dart';
import 'package:ion_token_analytics/src/http2_client/http2_connection.dart';
import 'package:ion_token_analytics/src/http2_client/http2_exceptions.dart';
import 'package:ion_token_analytics/src/http2_client/http2_stream_pool.dart';
import 'package:ion_token_analytics/src/http2_client/http2_web_socket.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_connection_status.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_request_options.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_request_response.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_subscription.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_web_socket_message.dart';
import 'package:ion_token_analytics/src/http2_client/sse_stream_parser.dart';

/// HTTP/2 client for making requests and managing stream subscriptions.
///
/// Uses [Http2StreamPool] for concurrency limiting instead of a raw counter,
/// an idle timer to prevent connection churn, and delegates SSE parsing
/// to [SseStreamParser].
///
/// Manages a single HTTP/2 connection to a host and port, automatically
/// establishing the connection when needed and closing it when all active
/// requests and subscriptions are complete.
///
/// Example usage:
/// ```dart
/// final client = Http2Client('example.com');
///
/// // Make a request
/// final response = await client.request<String>('/api/data');
/// print(response.data);
///
/// // Subscribe to a stream
/// await for (final message in client.subscribe<String>('/api/stream')) {
///   print(message);
/// }
/// ```
class Http2Client {
  /// Creates an HTTP/2 client for the specified host and port.
  Http2Client(this.host, {this.port = 443, this.scheme = 'https', AnalyticsLogger? logger})
    : _logger = logger;

  factory Http2Client.fromBaseUrl(String baseUrl, {AnalyticsLogger? logger}) {
    final uri = Uri.parse(baseUrl);
    final scheme = uri.scheme.isEmpty ? 'https' : uri.scheme;
    final host = uri.host;
    final port = uri.hasPort ? uri.port : (scheme == 'https' ? 443 : 80);
    return Http2Client(host, port: port, scheme: scheme, logger: logger);
  }

  /// SSE keepalive message types that should be ignored.
  static const String _keepalivePing = 'ping';
  static const String _keepalivePong = 'pong';

  /// The server hostname.
  final String host;

  /// The server port.
  final int port;

  /// The connection scheme (http or https).
  final String scheme;

  /// Optional logger for requests and responses.
  final AnalyticsLogger? _logger;

  late final Http2Connection _connection = Http2Connection(
    host,
    port: port,
    scheme: scheme,
    onGoAway: _handleGoAway,
  );
  late final Http2StreamPool _streamPool = Http2StreamPool(onLog: _logger?.log);

  Future<void>? _connectionFuture;
  bool _disposed = false;
  Timer? _idleTimer;

  static const Duration _idleTimeout = Duration(seconds: 30);

  /// Gets the current HTTP/2 connection.
  Http2Connection get connection => _connection;

  void _handleGoAway(int lastStreamId, int errorCode) {
    _logger?.log(
      '[Http2Client] GOAWAY received (lastStreamId: $lastStreamId, errorCode: $errorCode)',
    );
  }

  // ---------------------------------------------------------------------------
  // Request
  // ---------------------------------------------------------------------------

  /// Makes an HTTP/2 request.
  ///
  /// The [path] specifies the endpoint to request.
  /// The [data] is the request body (will be JSON-encoded if provided).
  /// The [queryParameters] will be appended to the path as a query string.
  /// The [options] configures the request method, timeout, and headers.
  ///
  /// Returns a [Response] containing the parsed response data.
  ///
  /// Example:
  /// ```dart
  /// final response = await client.request<Map<String, dynamic>>(
  ///   '/api/users',
  ///   data: {'name': 'John'},
  ///   queryParameters: {'filter': 'active'},
  ///   options: Http2RequestOptions(method: 'POST', timeout: Duration(seconds: 10)),
  /// );
  /// ```
  Future<Http2RequestResponse<T>> request<T>(
    String path, {
    Object? data,
    Map<String, String>? queryParameters,
    Http2RequestOptions? options,
  }) async {
    return _wrapWithConnectionErrorHandling(() async {
      _ensureNotDisposed();
      await _ensureConnection();

      final lease = await _streamPool.acquire();

      // Build method and URL for logging (needed in both try and catch blocks)
      final opts = options ?? Http2RequestOptions();
      final uri = Uri(
        path: path.startsWith('/') ? path : '/$path',
        queryParameters: queryParameters,
      );
      final fullPath = uri.toString();
      final url = '$scheme://$host$fullPath';
      final method = opts.method.toUpperCase();

      try {
        // Build request headers
        final requestHeaders = [
          Header.ascii(':method', method),
          Header.ascii(':scheme', scheme),
          Header.ascii(':path', fullPath),
          Header.ascii(':authority', host),
        ];

        // Add custom headers
        if (opts.headers != null) {
          for (final entry in opts.headers!.entries) {
            requestHeaders.add(Header.ascii(entry.key.toLowerCase(), entry.value));
          }
        }

        // Add content-type and encode data if provided
        Uint8List? bodyData;
        if (data != null) {
          final jsonData = jsonEncode(data);
          bodyData = Uint8List.fromList(utf8.encode(jsonData));
          requestHeaders
            ..add(Header.ascii('content-type', 'application/json'))
            ..add(Header.ascii('content-length', bodyData.length.toString()));
        }

        // Log request
        _logger?.logHttpRequest(method, url, data);

        // Make the request
        // Only set endStream on makeRequest when there is no body to send.
        final hasBody = bodyData != null && bodyData.isNotEmpty;
        final stream = _connection.transport!.makeRequest(requestHeaders, endStream: !hasBody);

        // Send body if present
        if (hasBody) {
          stream.sendData(bodyData, endStream: true);
        }

        // Wait for response with optional timeout
        // The response future will complete once the stream is fully read
        final responseFuture = _readResponse<T>(stream);
        final response = opts.timeout != null
            ? await responseFuture.timeout(opts.timeout!)
            : await responseFuture;

        _logger?.logHttpResponse(method, url, response.statusCode, response.data);
        return response;
      } catch (e, stackTrace) {
        _logger?.logHttpError(method, url, e, stackTrace);
        rethrow;
      } finally {
        lease.release();
        _scheduleIdleDisconnect();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // WebSocket subscribe
  // ---------------------------------------------------------------------------

  /// Creates a WebSocket subscription over HTTP/2.
  ///
  /// The [path] specifies the WebSocket endpoint.
  /// The [queryParameters] will be appended to the path as a query string.
  /// The [headers] can contain custom headers for the WebSocket handshake.
  ///
  /// Returns an [Http2Subscription] containing a stream of messages and a close method.
  /// The subscription will automatically increment the active operations counter,
  /// keeping the connection alive until the subscription is closed.
  ///
  /// To receive messages, listen to the [Http2Subscription.stream]:
  /// ```dart
  /// final subscription = await client.subscribe<String>(
  ///   '/api/updates',
  ///   queryParameters: {'channel': 'news'},
  ///   headers: {'authorization': 'Bearer token'},
  /// );
  ///
  /// // Listen to messages
  /// subscription.stream.listen((message) {
  ///   print('Received: $message');
  /// });
  ///
  /// // Close when done
  /// await subscription.close();
  /// ```
  Future<Http2Subscription<T>> subscribe<T>(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    return _wrapWithConnectionErrorHandling(() async {
      _ensureNotDisposed();
      await _ensureConnection();

      final lease = await _streamPool.acquire();

      try {
        final ws = await Http2WebSocket.fromHttp2Connection(
          _connection,
          path: path,
          queryParameters: queryParameters,
          headers: headers,
        );

        return _createManagedStream<T>(
          lease: lease,
          sourceStream: ws.stream
              .map((message) {
                if (message.type == WebSocketMessageType.text) {
                  if (T == String) return message.data as T;
                  final text = message.data as String;
                  // Skip ping/pong keepalive messages
                  final trimmed = text.trim();
                  if (trimmed == _keepalivePing || trimmed == _keepalivePong) return null;
                  return jsonDecode(text) as T;
                } else if (message.type == WebSocketMessageType.binary) {
                  if (message.data is T) return message.data as T;
                }
                return null;
              })
              .where((e) => e != null)
              .cast<T>(),
          onClose: ws.close,
        );
      } catch (e) {
        lease.release();
        _scheduleIdleDisconnect();
        rethrow;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // SSE subscribe
  // ---------------------------------------------------------------------------

  /// Creates a Server-Sent Events (SSE) subscription over HTTP/2.
  ///
  /// The [path] specifies the SSE endpoint.
  /// The [queryParameters] will be appended to the path as a query string.
  /// The [headers] can contain custom headers.
  ///
  /// Returns an [Http2Subscription] containing a stream of messages and a close method.
  /// The subscription will automatically increment the active operations counter,
  /// keeping the connection alive until the subscription is closed.
  Future<Http2Subscription<T>> subscribeSse<T>(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    return _wrapWithConnectionErrorHandling(() async {
      if (_disposed) throw const Http2ClientDisposedException();
      await _ensureConnection();

      final lease = await _streamPool.acquire();

      try {
        // Build the full path with query parameters
        final uri = Uri(
          path: path.startsWith('/') ? path : '/$path',
          queryParameters: queryParameters,
        );
        final fullPath = uri.toString();

        // Build request headers
        final requestHeaders = [
          Header.ascii(':method', 'GET'),
          Header.ascii(':scheme', scheme),
          Header.ascii(':path', fullPath),
          Header.ascii(':authority', host),
          Header.ascii('accept', 'text/event-stream'),
          Header.ascii('cache-control', 'no-cache'),
        ];

        if (headers != null) {
          for (final entry in headers.entries) {
            requestHeaders.add(Header.ascii(entry.key.toLowerCase(), entry.value));
          }
        }

        final stream = _connection.transport!.makeRequest(requestHeaders)
          ..sendData(Uint8List(0), endStream: true);

        final parsedStream = SseStreamParser<T>().parse(stream.incomingMessages);

        return _createManagedStream<T>(lease: lease, sourceStream: parsedStream);
      } catch (e) {
        lease.release();
        _scheduleIdleDisconnect();
        rethrow;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Managed stream helper — eliminates duplicate boilerplate
  // ---------------------------------------------------------------------------

  Http2Subscription<T> _createManagedStream<T>({
    required StreamLease lease,
    required Stream<T> sourceStream,
    void Function()? onClose,
  }) {
    final controller = StreamController<T>.broadcast();
    var isClosed = false;

    final streamSubscription = sourceStream.listen(
      (data) {
        if (!controller.isClosed) controller.add(data);
      },
      onError: (Object error, StackTrace stackTrace) {
        _addStreamError(controller, error, stackTrace);
      },
      onDone: () {
        if (!isClosed) {
          isClosed = true;
          if (!controller.isClosed) controller.close();
          lease.release();
          _scheduleIdleDisconnect();
        }
      },
    );

    Future<void> close() async {
      if (isClosed) return;
      isClosed = true;
      onClose?.call();
      await streamSubscription.cancel();
      if (!controller.isClosed) await controller.close();
      lease.release();
      _scheduleIdleDisconnect();
    }

    return Http2Subscription<T>(stream: controller.stream, close: close);
  }

  // ---------------------------------------------------------------------------
  // Connection management
  // ---------------------------------------------------------------------------

  /// Ensures an HTTP/2 connection is established.
  ///
  /// If a connection already exists, this method returns immediately.
  /// Otherwise, it creates a new connection. Prevents multiple simultaneous
  /// connection attempts by reusing the same connection Future.
  Future<void> _ensureConnection() async {
    _cancelIdleTimer();

    if (_connection.status is ConnectionStatusConnected) {
      final transport = _connection.transport;
      if (transport != null && transport.isOpen) return;
      await forceDisconnect();
    }

    // Capture the future to avoid race conditions
    final currentFuture = _connectionFuture;
    if (currentFuture != null) {
      await currentFuture;
      return;
    }

    // Create and store the connection future
    final newFuture = _connection.connect();
    _connectionFuture = newFuture;

    try {
      await newFuture;
    } finally {
      // Only clear if this is still the current future
      if (_connectionFuture == newFuture) _connectionFuture = null;
    }
  }

  void _cancelIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  /// Schedules a disconnect after [_idleTimeout] if no streams are active.
  void _scheduleIdleDisconnect() {
    if (_streamPool.activeCount > 0) return;
    _cancelIdleTimer();
    _idleTimer = Timer(_idleTimeout, () async {
      if (_streamPool.activeCount == 0 && !_disposed) {
        _logger?.log('[Http2Client] Idle timeout — disconnecting');
        await _connection.disconnect();
      }
    });
  }

  /// Forces disconnection of the underlying HTTP/2 connection.
  ///
  /// Use this when you detect that the connection has become stale
  /// (e.g., after receiving a SocketException with errno 9 "Bad file descriptor",
  /// or when the app transitions from background to foreground).
  ///
  /// After calling this method:
  /// - All active streams are considered invalid
  /// - The next request/subscription will establish a new connection
  /// - The client is NOT disposed and can still be used
  ///
  /// All active stream leases are force-released. The client is NOT disposed
  /// and can still be used — the next operation will reconnect.
  Future<void> forceDisconnect() async {
    // Clear the connection future to allow reconnection
    _connectionFuture = null;
    _cancelIdleTimer();
    _streamPool.forceReleaseAll();
    // Force disconnect the underlying connection
    await _connection.forceDisconnect();
  }

  /// Disposes the client and its underlying connection.
  ///
  /// After calling this method, no new requests or subscriptions can be made.
  /// Any active operations will continue until completion.
  Future<void> dispose() async {
    _disposed = true;
    _connectionFuture = null;
    _cancelIdleTimer();
    _streamPool.dispose();
    await _connection.dispose();
  }

  void _ensureNotDisposed() {
    if (_disposed) throw StateError('Cannot use a disposed Http2Client');
  }

  // ---------------------------------------------------------------------------
  // Response reading
  // ---------------------------------------------------------------------------

  /// Reads the response from an HTTP/2 stream.
  ///
  /// Collects all data frames and headers, then parses the response body
  /// based on the content-type header.
  Future<Http2RequestResponse<T>> _readResponse<T>(ClientTransportStream stream) async {
    final completer = Completer<Http2RequestResponse<T>>();
    final dataBuffer = <int>[];
    Map<String, String>? responseHeaders;
    int? statusCode;

    stream.incomingMessages.listen(
      (StreamMessage message) {
        if (message is HeadersStreamMessage) {
          responseHeaders = _parseHeaders(message.headers);
          final status = responseHeaders![':status'];
          if (status != null) statusCode = int.tryParse(status);
        } else if (message is DataStreamMessage) {
          dataBuffer.addAll(message.bytes);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          if (Http2StaleConnectionException.isStaleConnectionError(error)) {
            completer.completeError(Http2StaleConnectionException(error), stackTrace);
          } else {
            completer.completeError(error, stackTrace);
          }
        }
      },
      onDone: () {
        // Don't try to complete if already completed (e.g., by onError)
        if (completer.isCompleted) return;

        try {
          T? parsedData;

          if (dataBuffer.isNotEmpty) {
            final contentType = responseHeaders?['content-type'] ?? '';

            if (contentType.contains('application/json')) {
              // Parse JSON response
              final jsonString = utf8.decode(dataBuffer);
              parsedData = jsonDecode(jsonString) as T?;
            } else if (T == String) {
              // Return as string
              parsedData = utf8.decode(dataBuffer) as T;
            } else if (T == Uint8List || T == List<int>) {
              // Return as bytes
              parsedData = Uint8List.fromList(dataBuffer) as T;
            } else {
              // Try JSON parsing as fallback
              try {
                final jsonString = utf8.decode(dataBuffer);
                parsedData = jsonDecode(jsonString) as T?;
              } catch (_) {
                // If all else fails, try to return the raw data
                parsedData = dataBuffer as T?;
              }
            }
          }

          completer.complete(
            Http2RequestResponse<T>(
              data: parsedData,
              statusCode: statusCode,
              headers: responseHeaders,
            ),
          );
        } catch (e, stackTrace) {
          if (!completer.isCompleted) completer.completeError(e, stackTrace);
        }
      },
    );

    return completer.future;
  }

  /// Parses HTTP/2 headers into a map.
  Map<String, String> _parseHeaders(List<Header> headers) {
    final result = <String, String>{};
    for (final header in headers) {
      result[utf8.decode(header.name)] = utf8.decode(header.value);
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Error handling
  // ---------------------------------------------------------------------------

  Future<T> _wrapWithConnectionErrorHandling<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      if (Http2StaleConnectionException.isStaleConnectionError(e)) {
        _logger?.log('[Http2Client] Stale connection error (${e.runtimeType}: $e)');
        await forceDisconnect();
        throw Http2StaleConnectionException(e);
      }
      rethrow;
    }
  }

  void _addStreamError<T>(StreamController<T> controller, Object error, StackTrace stackTrace) {
    if (controller.isClosed) return;

    if (Http2StaleConnectionException.isStaleConnectionError(error)) {
      _logger?.log(
        '[Http2Client] Stale connection on active stream (${error.runtimeType}: $error)',
      );
      unawaited(forceDisconnect());
      controller.addError(Http2StaleConnectionException(error), stackTrace);
      return;
    }

    controller.addError(error, stackTrace);
  }
}
