// SPDX-License-Identifier: ice License 1.0

/// Options for configuring HTTP/2 requests.
///
/// Allows customization of request method, timeout, and headers.
class Http2RequestOptions {
  /// Creates request options.
  ///
  /// The [method] defaults to 'GET' if not specified.
  /// The [timeout] is optional and specifies how long to wait for a response.
  /// The [headers] can contain custom HTTP headers for the request.
  Http2RequestOptions({this.method = 'GET', this.timeout, this.headers});

  /// HTTP method to use for the request (e.g., 'GET', 'POST', 'PUT', 'DELETE').
  final String method;

  /// Optional timeout duration for the request.
  ///
  /// If specified, the request will fail if it doesn't complete within this duration.
  final Duration? timeout;

  /// Optional custom headers to include in the request.
  final Map<String, String>? headers;
}
