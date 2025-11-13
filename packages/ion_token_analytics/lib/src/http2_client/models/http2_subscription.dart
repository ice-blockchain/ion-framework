/// A subscription to an HTTP/2 stream.
///
/// Wraps a stream of data and provides a method to close the underlying stream.
class Http2Subscription<T> {
  Http2Subscription({required this.stream, required this.close});

  /// The stream of data received from the HTTP/2 connection.
  final Stream<T> stream;

  /// Closes the HTTP/2 stream.
  final Future<void> Function() close;
}
