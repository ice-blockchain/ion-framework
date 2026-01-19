// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io' hide WebSocket;

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/core/providers/internet_connection_checker_provider.r.dart';
import 'package:ion/app/features/core/providers/internet_status_stream_provider.r.dart';
import 'package:ion/app/features/core/providers/relay_proxy_domains_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_disliked_connect_urls_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_proxy_domain_preference_provider.r.dart';
import 'package:ion/app/features/user/providers/relays/relays_reachability_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/utils/logging.dart';

mixin RelayCreateMixin {
  Future<IonConnectRelay> createRelay(Ref ref, String url) async {
    final dislikedConnectUrls = ref.read(relayDislikedConnectUrlsProvider(url));
    final candidates = ref.read(relayConnectUrisProvider(url));
    final proxyDomains = ref.read(relayProxyDomainsProvider);
    final savedPreferredDomain = ref.read(relayProxyDomainPreferenceProvider(url));

    ConnectionState? lastConnectionState;
    var triggeredConnectivityCheck = false;

    for (final connectUri in candidates) {
      final connectUrl = connectUri.toString();
      if (dislikedConnectUrls.contains(connectUrl)) {
        continue;
      }

      final socket = WebSocket(connectUri);
      final relay = IonConnectRelay(
        url: url,
        connectUrl: connectUrl,
        socket: socket,
      );

      final connectionState = await socket.connection.firstWhere(
        (state) => state is Connected || state is Reconnected || state is Disconnected,
      );

      lastConnectionState = connectionState;

      final usedDomain = proxyDomains.firstWhereOrNull(
        (d) => connectUri.host.endsWith(d),
      );

      final hasInternetConnection = ref.read(hasInternetConnectionProvider);
      final isUnreachable = _isRelayUnreachable(
        connectionState: connectionState,
        hasInternetConnection: hasInternetConnection,
      );

      if (!isUnreachable) {
        // Persist which proxy domain worked for this logical relay.
        // If we connected directly (no proxy domain), clear any previously saved preference.
        ref
            .read(relayProxyDomainPreferenceProvider(url).notifier)
            .persistPreferredProxyDomain(usedDomain);

        await ref.read(relayReachabilityProvider.notifier).clear(url);
        return relay;
      }

      // Report failover (sampled) with what failed.
      final err = (connectionState is Disconnected) ? connectionState.error : null;
      reportFailover(
        Exception(
          '[RELAY] Relay connection failover for logical URL: $url and connect URL $connectUrl with reason${err != null ? ' (${err.runtimeType}: $err)' : ''}',
        ),
        StackTrace.current,
        tag: 'relay_failover_connect',
      );

      // If the currently saved preferred proxy domain was attempted and failed, clear it
      // so subsequent relay creations don't keep trying a known-bad preference first.
      if (usedDomain == savedPreferredDomain) {
        ref
            .read(relayProxyDomainPreferenceProvider(url).notifier)
            .persistPreferredProxyDomain(null);
      }

      // Trigger an immediate connectivity check on network-like WebSocket errors
      // to update the global status promptly.
      if (!triggeredConnectivityCheck) {
        triggeredConnectivityCheck = true;
        unawaited(ref.read(internetConnectionCheckerProvider).checkNow());
      }

      socket.close();
    }

    // All candidates were unreachable.
    if (lastConnectionState != null) {
      await _updateRelayReachabilityInfo(ref, url);
      throw RelayUnreachableException(url);
    }

    // Should not happen because candidates always include at least the logical URL.
    throw RelayUnreachableException(url);
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
