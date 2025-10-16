// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/core/providers/internet_connection_checker_provider.r.dart';
import 'package:ion/app/features/core/providers/internet_status_stream_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/user/providers/relays/relays_reachability_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';

mixin RelayCreateMixin {
  Future<IonConnectRelay> createRelay(Ref ref, String url) async {
    final socket = WebSocket(Uri.parse(url));

    final relay = IonConnectRelay(url: url, socket: socket);
    final connectionState = await socket.connection.firstWhere(
      (state) => state is Connected || state is Reconnected || state is Disconnected,
    );

    final hasInternetConnection = ref.read(hasInternetConnectionProvider);
    if (_isRelayUnreachable(
      connectionState: connectionState,
      hasInternetConnection: hasInternetConnection,
    )) {
      // Trigger an immediate connectivity check on network-like WebSocket errors
      // to update the global status promptly.
      unawaited(ref.read(internetConnectionCheckerProvider).checkNow());
      socket.close();
      await _updateRelayReachabilityInfo(ref, url);
      throw RelayUnreachableException(url);
    }

    await ref.read(relayReachabilityProvider.notifier).clear(url);

    return relay;
  }

  bool _isRelayUnreachable({
    required ConnectionState connectionState,
    required bool hasInternetConnection,
  }) {
    if (connectionState is! Disconnected || connectionState.error == null) {
      return false;
    }

    Logger.error(connectionState.error!, message: '[RELAY] has disconnected with error');

    if (!hasInternetConnection) {
      return false;
    }

    return switch (connectionState.error) {
      SocketException() || TimeoutException() => true,
      _ => false,
    };
  }

  Future<void> _updateRelayReachabilityInfo(Ref ref, String url) async {
    final relayReachabilityInfo = ref.read(relayReachabilityProvider.notifier).get(url);
    final updatedReachabilityInfo = _getUpdatedReachabilityInfo(url, relayReachabilityInfo);
    await ref.read(relayReachabilityProvider.notifier).save(updatedReachabilityInfo);
  }

  RelayReachabilityInfo _getUpdatedReachabilityInfo(
    String url,
    RelayReachabilityInfo? reachabilityInfo,
  ) {
    if (reachabilityInfo == null) {
      return RelayReachabilityInfo(
        relayUrl: url,
        failedToReachCount: 1,
        lastFailedToReachDate: DateTime.now(),
      );
    }
    final timeDifference = DateTime.now().difference(reachabilityInfo.lastFailedToReachDate).abs();
    if (timeDifference.inHours < 1) {
      return reachabilityInfo;
    }

    return RelayReachabilityInfo(
      relayUrl: url,
      failedToReachCount: reachabilityInfo.failedToReachCount + 1,
      lastFailedToReachDate: DateTime.now(),
    );
  }
}
