// SPDX-License-Identifier: ice License 1.0

/// Represents the current state of an HTTP/2 connection.
sealed class ConnectionStatus {
  const ConnectionStatus();
}

/// Connection is being established.
final class ConnectionStatusConnecting extends ConnectionStatus {
  const ConnectionStatusConnecting();
}

/// Connection is established and ready to use.
final class ConnectionStatusConnected extends ConnectionStatus {
  const ConnectionStatusConnected();
}

/// Connection is being closed.
final class ConnectionStatusDisconnecting extends ConnectionStatus {
  const ConnectionStatusDisconnecting();
}

/// Connection is closed.
final class ConnectionStatusDisconnected extends ConnectionStatus {
  const ConnectionStatusDisconnected([this.exception]);

  /// The exception that caused the disconnection, if any.
  final Exception? exception;
}
