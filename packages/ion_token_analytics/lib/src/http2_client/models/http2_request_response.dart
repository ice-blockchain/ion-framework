/// Response from an HTTP/2 request.
class Http2RequestResponse<T> {
  /// Creates an HTTP/2 response.
  ///
  /// The [data] contains the parsed response body.
  /// The [statusCode] is the HTTP status code (e.g., 200, 404).
  /// The [headers] contains the response headers.
  Http2RequestResponse({this.data, this.statusCode, this.headers});

  /// The response data of type T.
  final T? data;

  /// The HTTP status code.
  final int? statusCode;

  /// The response headers.
  ///
  /// Contains metadata about the response such as content-type, cache-control, etc.
  final Map<String, String>? headers;
}
