// SPDX-License-Identifier: ice License 1.0

/// A subscription to a network stream (SSE or WebSocket).
class NetworkSubscription<T> {
  NetworkSubscription({required this.stream, required this.close});

  final Stream<T> stream;
  final Future<void> Function() close;
}
