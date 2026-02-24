// SPDX-License-Identifier: ice License 1.0

/// Logger interface for ION Identity client diagnostics and passkey workaround logs.
/// Implementations can forward to the app's logging (e.g. [Logger]).
abstract class IonIdentityLogger {
  void log(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });

  void info(String message);

  void warning(String message);

  void error(
    Object error, {
    StackTrace? stackTrace,
    String? message,
  });
}
