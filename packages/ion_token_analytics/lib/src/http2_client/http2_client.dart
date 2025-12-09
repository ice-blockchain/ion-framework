// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http2/http2.dart';
import 'package:ion_token_analytics/src/http2_client/http2_connection.dart';
import 'package:ion_token_analytics/src/http2_client/http2_web_socket.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_connection_status.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_request_options.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_request_response.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_subscription.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_web_socket_message.dart';

/// HTTP/2 client for making requests and WebSocket subscriptions.
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
  Http2Client(this.host, {this.port = 443, this.scheme = 'https', Http2Connection? connection}) {
    _connection = connection ?? Http2Connection(host, port: port, scheme: scheme);
  }

  factory Http2Client.fromBaseUrl(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    final scheme = uri.scheme.isEmpty ? 'https' : uri.scheme;
    final host = uri.host;
    final port = uri.hasPort ? uri.port : (scheme == 'https' ? 443 : 80);

    return Http2Client(host, port: port, scheme: scheme);
  }

  /// The server hostname.
  final String host;

  /// The server port.
  final int port;

  /// The connection scheme (http or https).
  final String scheme;

  late final Http2Connection _connection;
  int _activeStreams = 0;
  Future<void>? _connectionFuture;
  bool _disposed = false;

  /// Gets the current HTTP/2 connection.
  Http2Connection get connection => _connection;

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
    if (_disposed) {
      throw StateError('Cannot make request on disposed Http2Client');
    }
    await _ensureConnection();
    _activeStreams++;

    try {
      final opts = options ?? Http2RequestOptions();

      // Build the full path with query parameters
      final uri = Uri(
        path: path.startsWith('/') ? path : '/$path',
        queryParameters: queryParameters,
      );
      final fullPath = uri.toString();

      // Build request headers
      final requestHeaders = [
        Header.ascii(':method', opts.method.toUpperCase()),
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

      // Make the request
      final stream = _connection.transport!.makeRequest(requestHeaders);

      // Send body if present
      if (bodyData != null) {
        stream.sendData(bodyData, endStream: true);
      } else {
        stream.sendData(Uint8List(0), endStream: true);
      }

      // Wait for response with optional timeout
      // The response future will complete once the stream is fully read
      final responseFuture = _readResponse<T>(stream);
      final response = opts.timeout != null
          ? await responseFuture.timeout(opts.timeout!)
          : await responseFuture;

      return response;
    } finally {
      _activeStreams--;
      await _maybeCloseConnection();
    }
  }

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
    if (_disposed) {
      throw StateError('Cannot create subscription on disposed Http2Client');
    }
    await _ensureConnection();
    _activeStreams++;

    try {
      final ws = await Http2WebSocket.fromHttp2Connection(
        _connection,
        path: path,
        queryParameters: queryParameters,
        headers: headers,
      );

      final controller = StreamController<T>.broadcast();
      var isClosed = false;

      final streamSubscription = ws.stream.listen(
        (message) {
          if (controller.isClosed) return;

          if (message.type == WebSocketMessageType.text) {
            if (T == String) {
              controller.add(message.data as T);
            } else {
              try {
                final parsed = jsonDecode(message.data as String);
                controller.add(parsed as T);
              } catch (e) {
                controller.addError(e);
              }
            }
          } else if (message.type == WebSocketMessageType.binary) {
            if (message.data is T) {
              controller.add(message.data as T);
            }
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!controller.isClosed) {
            controller.addError(error, stackTrace);
          }
        },
        onDone: () async {
          if (!isClosed) {
            isClosed = true;
            if (!controller.isClosed) {
              await controller.close();
            }
            _activeStreams--;
            await _maybeCloseConnection();
          }
        },
      );

      // Manual close method
      Future<void> close() async {
        if (isClosed) return;
        isClosed = true;

        // Close the WebSocket connection first
        ws.close();

        await streamSubscription.cancel();

        if (!controller.isClosed) {
          await controller.close();
        }

        _activeStreams--;
        await _maybeCloseConnection();
      }

      return Http2Subscription<T>(stream: controller.stream, close: close);
    } catch (e) {
      _activeStreams--;
      await _maybeCloseConnection();
      rethrow;
    }
  }

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
    if (_disposed) {
      throw StateError('Cannot create subscription on disposed Http2Client');
    }
    await _ensureConnection();
    _activeStreams++;

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

      // Add custom headers
      if (headers != null) {
        for (final entry in headers.entries) {
          requestHeaders.add(Header.ascii(entry.key.toLowerCase(), entry.value));
        }
      }

      // Make the request
      final stream = _connection.transport!.makeRequest(requestHeaders)
        ..sendData(Uint8List(0), endStream: true);

      final controller = StreamController<T>.broadcast();
      var isClosed = false;

      // SSE parsing state
      var buffer = '';

      final streamSubscription = stream.incomingMessages.listen(
        (message) {
          if (controller.isClosed) return;

          if (message is DataStreamMessage) {
            final chunk = utf8.decode(message.bytes);
            buffer += chunk;

            while (buffer.contains('\n\n')) {
              final index = buffer.indexOf('\n\n');
              final eventString = buffer.substring(0, index);
              buffer = buffer.substring(index + 2);

              _processSseEvent<T>(eventString, controller);
            }
          } else if (message is HeadersStreamMessage) {
            // Check status code?
            final headers = _parseHeaders(message.headers);
            final status = headers[':status'];
            if (status != null && status != '200') {
              controller.addError(Exception('SSE connection failed with status $status'));
            }
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!controller.isClosed) {
            controller.addError(error, stackTrace);
          }
        },
        onDone: () async {
          if (!isClosed) {
            isClosed = true;
            if (!controller.isClosed) {
              await controller.close();
            }
            _activeStreams--;
            await _maybeCloseConnection();
          }
        },
      );

      // Manual close method
      Future<void> close() async {
        if (isClosed) return;
        isClosed = true;

        // Cancel the stream subscription (this might not close the server side immediately)
        await streamSubscription.cancel();

        // We can't easily "close" an HTTP/2 stream from client side other than RST_STREAM
        // but the transport doesn't expose that easily.
        // For now, we rely on cancelling the listener.

        if (!controller.isClosed) {
          await controller.close();
        }

        _activeStreams--;
        await _maybeCloseConnection();
      }

      return Http2Subscription<T>(stream: controller.stream, close: close);
    } catch (e) {
      _activeStreams--;
      await _maybeCloseConnection();
      rethrow;
    }
  }

  void _processSseEvent<T>(String eventString, StreamController<T> controller) {
    final lines = eventString.split('\n');
    String? data;
    // String? event; // We could use this if we wanted to support named events

    for (final line in lines) {
      if (line.startsWith('data:')) {
        final lineData = line.substring(5).trim();
        if (data == null) {
          data = lineData;
        } else {
          data = '$data\n$lineData';
        }
      }
      // Handle 'event:', 'id:', 'retry:' if needed
    }

    if (data != null) {
      if (T == String) {
        controller.add(data as T);
      } else {
        try {
          final parsed = jsonDecode(data);
          controller.add(parsed as T);
        } catch (e) {
          controller.addError(e);
        }
      }
    }
  }

  /// Ensures an HTTP/2 connection is established.
  ///
  /// If a connection already exists, this method returns immediately.
  /// Otherwise, it creates a new connection. Prevents multiple simultaneous
  /// connection attempts by reusing the same connection Future.
  Future<void> _ensureConnection() async {
    if (_connection.status is ConnectionStatusConnected) {
      return;
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
      if (_connectionFuture == newFuture) {
        _connectionFuture = null;
      }
    }
  }

  /// Closes the connection if there are no active operations.
  ///
  /// This is called automatically after each request or subscription completes.
  Future<void> _maybeCloseConnection() async {
    if (_activeStreams == 0) {
      await _connection.disconnect();
    }
  }

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
          if (status != null) {
            statusCode = int.tryParse(status);
          }
        } else if (message is DataStreamMessage) {
          dataBuffer.addAll(message.bytes);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
      onDone: () {
        // Don't try to complete if already completed (e.g., by onError)
        if (completer.isCompleted) {
          return;
        }

        try {
          T? parsedData;

          if (dataBuffer.isNotEmpty) {
            final contentType = responseHeaders?['content-type'] ?? '';

            if (contentType.contains('application/json')) {
              // Parse JSON response
              final jsonString = utf8.decode(dataBuffer);
              final decoded = jsonDecode(jsonString);
              parsedData = decoded as T?;
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
                final decoded = jsonDecode(jsonString);
                parsedData = decoded as T?;
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
          if (!completer.isCompleted) {
            completer.completeError(e, stackTrace);
          }
        }
      },
    );

    return completer.future;
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

  /// Disposes the client and its underlying connection.
  ///
  /// After calling this method, no new requests or subscriptions can be made.
  /// Any active operations will continue until completion.
  Future<void> dispose() async {
    _disposed = true;
    await _connection.dispose();
  }
}
