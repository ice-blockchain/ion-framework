import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http2/http2.dart';
import 'package:ion_token_analytics/src/http2_client/http2_connection.dart';
import 'package:ion_token_analytics/src/http2_client/http2_web_socket.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_request_options.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_request_response.dart';
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
  Http2Client(this.host, {this.port = 443, this.scheme = 'https'});

  /// The server hostname.
  final String host;

  /// The server port.
  final int port;

  /// The connection scheme (http or https).
  final String scheme;

  Http2Connection? _connection;
  int _activeOperations = 0;
  Completer<void>? _connectionLock;

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
  ///   options: Options(method: 'POST', timeout: Duration(seconds: 10)),
  /// );
  /// ```
  Future<Http2RequestResponse<T>> request<T>(
    String path, {
    Object? data,
    Map<String, String>? queryParameters,
    Http2RequestOptions? options,
  }) async {
    await _ensureConnection();
    _activeOperations++;

    try {
      final opts = options ?? Http2RequestOptions();

      // Build the full path with query parameters
      var fullPath = path.isEmpty ? '/' : path;
      if (queryParameters != null && queryParameters.isNotEmpty) {
        final queryString = queryParameters.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        fullPath = '$fullPath?$queryString';
      }

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
      final stream = _connection!.transport.makeRequest(requestHeaders);

      // Send body if present
      if (bodyData != null) {
        stream.sendData(bodyData, endStream: true);
      } else {
        stream.sendData(Uint8List(0), endStream: true);
      }

      // Wait for response with optional timeout
      final responseFuture = _readResponse<T>(stream);
      if (opts.timeout != null) {
        return await responseFuture.timeout(opts.timeout!);
      }
      return await responseFuture;
    } finally {
      _activeOperations--;
      await _maybeCloseConnection();
    }
  }

  /// Subscribes to a WebSocket stream.
  ///
  /// The [path] specifies the WebSocket endpoint.
  /// The [queryParameters] will be appended to the path as a query string.
  /// The [headers] can contain custom headers for the WebSocket handshake.
  ///
  /// Returns a stream of messages of type T. The stream will automatically
  /// close when the WebSocket connection closes.
  ///
  /// Example:
  /// ```dart
  /// await for (final message in client.subscribe<String>(
  ///   '/api/updates',
  ///   queryParameters: {'channel': 'news'},
  ///   headers: {'authorization': 'Bearer token'},
  /// )) {
  ///   print('Received: $message');
  /// }
  /// ```
  Stream<T> subscribe<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async* {
    await _ensureConnection();
    _activeOperations++;

    try {
      final ws = await Http2WebSocket.fromHttp2Connection(
        _connection!,
        path: path,
        queryParameters: queryParameters,
        headers: headers,
      );

      await for (final message in ws.stream) {
        if (message.type == WebSocketMessageType.text) {
          // Parse text messages based on type T
          if (T == String) {
            yield message.data as T;
          } else {
            // Try to parse as JSON
            try {
              final parsed = jsonDecode(message.data as String);
              yield parsed as T;
            } catch (_) {
              // If parsing fails, yield the raw string if possible
              if (message.data is T) {
                yield message.data as T;
              }
            }
          }
        } else if (message.type == WebSocketMessageType.binary) {
          // For binary messages, yield as-is if type matches
          if (message.data is T) {
            yield message.data as T;
          }
        }
      }
    } finally {
      _activeOperations--;
      await _maybeCloseConnection();
    }
  }

  /// Ensures an HTTP/2 connection is established.
  ///
  /// If a connection already exists, this method returns immediately.
  /// Otherwise, it creates a new connection. Uses a lock to prevent
  /// multiple simultaneous connection attempts.
  Future<void> _ensureConnection() async {
    // Wait for any ongoing connection attempt
    if (_connectionLock != null) {
      await _connectionLock!.future;
    }

    if (_connection != null) {
      return;
    }

    // Create a new lock for this connection attempt
    _connectionLock = Completer<void>();

    try {
      _connection = await Http2Connection.connect(host, port: port, scheme: scheme);
    } finally {
      _connectionLock!.complete();
      _connectionLock = null;
    }
  }

  /// Closes the connection if there are no active operations.
  ///
  /// This is called automatically after each request or subscription completes.
  Future<void> _maybeCloseConnection() async {
    if (_activeOperations == 0 && _connection != null) {
      await _connection!.close();
      _connection = null;
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
      onError: completer.completeError,
      onDone: () {
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
          completer.completeError(e, stackTrace);
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

  /// Closes the client and its underlying connection.
  ///
  /// After calling this method, no new requests or subscriptions can be made.
  /// Any active operations will continue until completion.
  Future<void> close() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
    }
  }
}
