// SPDX-License-Identifier: ice License 1.0

/// Interface for logging in the analytics client.
abstract class AnalyticsLogger {
  /// Logs a message.
  void log(String message);

  /// Logs an error with optional stack trace.
  void error(String message, {Object? error, StackTrace? stackTrace});
}
