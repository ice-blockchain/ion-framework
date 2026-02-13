// SPDX-License-Identifier: ice License 1.0

/// Exception thrown when a network request fails with an HTTP status error.
sealed class NetworkException implements Exception {
  const NetworkException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Exception thrown when an HTTP request fails with a non-success status code.
class HttpStatusException extends NetworkException {
  const HttpStatusException({required this.statusCode, required this.path, String? message})
    : super(message ?? 'Request failed with status $statusCode: $path');

  final int statusCode;
  final String path;

  bool get isNotFound => statusCode == 404;
}
