// SPDX-License-Identifier: ice License 1.0

/// Interface for logging in the analytics client.
abstract class AnalyticsLogger {
  /// Logs a message.
  void log(String message);

  /// Logs an error with optional stack trace.
  void error(String message, {Object? error, StackTrace? stackTrace});

  /// Logs an HTTP request.
  void logHttpRequest(String method, String url, Object? data);

  /// Logs an HTTP response.
  void logHttpResponse(String method, String url, int? statusCode, Object? data);

  /// Logs an HTTP error.
  void logHttpError(String method, String url, Object error, StackTrace stackTrace);
}
