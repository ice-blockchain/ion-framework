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
class Http2Client {
  Http2Client(this.host, {this.port = 443, this.scheme = 'https', AnalyticsLogger? logger})
    : _logger = logger;

  factory Http2Client.fromBaseUrl(String baseUrl, {AnalyticsLogger? logger}) {
    final uri = Uri.parse(baseUrl);
    final scheme = uri.scheme.isEmpty ? 'https' : uri.scheme;
    final host = uri.host;
    final port = uri.hasPort ? uri.port : (scheme == 'https' ? 443 : 80);
    return Http2Client(host, port: port, scheme: scheme, logger: logger);
  }

  /// Keepalive messages to ignore in WebSocket streams.
  static const String _keepalivePing = 'ping';
  static const String _keepalivePong = 'pong';

  final String host;
  final int port;
  final String scheme;
  final AnalyticsLogger? _logger;

  late final Http2Connection _connection = Http2Connection(
    host,
    port: port,
    scheme: scheme,
    onGoAway: _handleGoAway,
  );
  late final Http2StreamPool _streamPool = Http2StreamPool(
    onLog: _logger?.log,
  );

  Future<void>? _connectionFuture;
  bool _disposed = false;
  Timer? _idleTimer;

  static const Duration _idleTimeout = Duration(seconds: 30);

  Http2Connection get connection => _connection;

  void _handleGoAway(int lastStreamId, int errorCode) {
    _logger?.log(
      '[Http2Client] GOAWAY received (lastStreamId: $lastStreamId, errorCode: $errorCode)',
    );
  }

  // ---------------------------------------------------------------------------
  // Request
  // ---------------------------------------------------------------------------

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

      final opts = options ?? Http2RequestOptions();
      final uri = Uri(
        path: path.startsWith('/') ? path : '/$path',
        queryParameters: queryParameters,
      );
      final fullPath = uri.toString();
      final url = '$scheme://$host$fullPath';
      final method = opts.method.toUpperCase();

      try {
        final requestHeaders = [
          Header.ascii(':method', method),
          Header.ascii(':scheme', scheme),
          Header.ascii(':path', fullPath),
          Header.ascii(':authority', host),
        ];

        if (opts.headers != null) {
          for (final entry in opts.headers!.entries) {
            requestHeaders.add(Header.ascii(entry.key.toLowerCase(), entry.value));
          }
        }

        Uint8List? bodyData;
        if (data != null) {
          final jsonData = jsonEncode(data);
          bodyData = Uint8List.fromList(utf8.encode(jsonData));
          requestHeaders
            ..add(Header.ascii('content-type', 'application/json'))
            ..add(Header.ascii('content-length', bodyData.length.toString()));
        }

        _logger?.logHttpRequest(method, url, data);

        // Only set endStream on makeRequest when there is no body to send.
        final hasBody = bodyData != null && bodyData.isNotEmpty;
        final stream = _connection.transport!.makeRequest(
          requestHeaders,
          endStream: !hasBody,
        );

        if (hasBody) {
          stream.sendData(bodyData, endStream: true);
        }

        final responseFuture = _readResponse<T>(stream);
        final response =
            opts.timeout != null ? await responseFuture.timeout(opts.timeout!) : await responseFuture;

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
          sourceStream: ws.stream.map((message) {
            if (message.type == WebSocketMessageType.text) {
              if (T == String) return message.data as T;
              final text = message.data as String;
              final trimmed = text.trim();
              if (trimmed == _keepalivePing || trimmed == _keepalivePong) return null;
              return jsonDecode(text) as T;
            } else if (message.type == WebSocketMessageType.binary) {
              if (message.data is T) return message.data as T;
            }
            return null;
          }).where((e) => e != null).cast<T>(),
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
        final uri = Uri(
          path: path.startsWith('/') ? path : '/$path',
          queryParameters: queryParameters,
        );
        final fullPath = uri.toString();

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

        return _createManagedStream<T>(
          lease: lease,
          sourceStream: parsedStream,
        );
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

  Future<void> _ensureConnection() async {
    _cancelIdleTimer();

    if (_connection.status is ConnectionStatusConnected) {
      final transport = _connection.transport;
      if (transport != null && transport.isOpen) return;
      await forceDisconnect();
    }

    final currentFuture = _connectionFuture;
    if (currentFuture != null) {
      await currentFuture;
      return;
    }

    final newFuture = _connection.connect();
    _connectionFuture = newFuture;

    try {
      await newFuture;
    } finally {
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
  /// All active stream leases are force-released. The client is NOT disposed
  /// and can still be used — the next operation will reconnect.
  Future<void> forceDisconnect() async {
    _connectionFuture = null;
    _cancelIdleTimer();
    _streamPool.forceReleaseAll();
    await _connection.forceDisconnect();
  }

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
        if (completer.isCompleted) return;

        try {
          T? parsedData;

          if (dataBuffer.isNotEmpty) {
            final contentType = responseHeaders?['content-type'] ?? '';

            if (contentType.contains('application/json')) {
              final jsonString = utf8.decode(dataBuffer);
              parsedData = jsonDecode(jsonString) as T?;
            } else if (T == String) {
              parsedData = utf8.decode(dataBuffer) as T;
            } else if (T == Uint8List || T == List<int>) {
              parsedData = Uint8List.fromList(dataBuffer) as T;
            } else {
              try {
                final jsonString = utf8.decode(dataBuffer);
                parsedData = jsonDecode(jsonString) as T?;
              } catch (_) {
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
