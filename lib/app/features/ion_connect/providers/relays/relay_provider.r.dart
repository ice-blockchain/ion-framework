// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/providers/mixins/relay_active_mixin.dart';
import 'package:ion/app/features/ion_connect/providers/mixins/relay_auth_mixin.dart';
import 'package:ion/app/features/ion_connect/providers/mixins/relay_closed_mixin.dart';
import 'package:ion/app/features/ion_connect/providers/mixins/relay_create_mixin.dart';
import 'package:ion/app/features/ion_connect/providers/mixins/relay_timer_mixin.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_auth_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_disliked_connect_urls_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/utils/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'relay_provider.r.g.dart';

typedef RelaysState = Map<String, IonConnectRelay>;

@Riverpod(keepAlive: true)
class Relay extends _$Relay
    with RelayTimerMixin, RelayCreateMixin, RelayAuthMixin, RelayClosedMixin, RelayActiveMixin {
  @override
  Future<IonConnectRelay> build(String url, {bool anonymous = false}) async {
    final dislikedConnectUrlsNotifier = ref.read(relayDislikedConnectUrlsProvider(url).notifier);

    try {
      while (true) {
        final relay = await createRelay(ref, url);
        try {
          // Treat auth init as part of relay creation.
          // If auth fails with an auth-required loop, we failover by retrying with the next connect URL.
          if (!anonymous) {
            await initializeAuth(relay, ref);
          }

          // Only after relay is usable, start the rest of the lifecycle listeners.
          trackRelayAsActive(relay, ref);
          initializeRelayTimer(relay, ref);
          initializeRelayClosedListener(relay, ref);

          ref.onDispose(relay.close);
          return relay;
        } catch (e, st) {
          // If we are stuck in an auth-required loop, consider this connect URL unusable and retry.
          if (!anonymous && RelayAuthService.isRelayAuthError(e)) {
            final connectUrl = relay.connectUrl;
            final added = dislikedConnectUrlsNotifier.add(connectUrl);

            // Close the bad relay before retrying.
            relay.close();

            // Safety: if we can't make progress (same URL again), stop retrying.
            if (!added) {
              rethrow;
            }

            reportFailover(
              Exception(
                '[RELAY] Relay auth failover for logical URL: $url and connect URL: $connectUrl; reason: $e',
              ),
              st,
              tag: 'relay_failover_auth',
            );
            continue;
          }

          // Non-auth errors bubble up.
          relay.close();
          rethrow;
        }
      }
    } catch (e) {
      Logger.warning(
        '[RELAY] Failed to create relay for URL: $url, error: $e',
      );
      Timer(const Duration(minutes: 1), () {
        ref.invalidateSelf();
      });
      rethrow;
    }
  }
}
