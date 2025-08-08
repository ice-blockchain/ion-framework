// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_logger_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/mixins/relay_active_mixin.dart';
import 'package:ion/app/features/ion_connect/providers/mixins/relay_auth_mixin.dart';
import 'package:ion/app/features/ion_connect/providers/mixins/relay_closed_mixin.dart';
import 'package:ion/app/features/ion_connect/providers/mixins/relay_create_mixin.dart';
import 'package:ion/app/features/ion_connect/providers/mixins/relay_timer_mixin.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_logging_wrapper.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'relay_provider.r.g.dart';

typedef RelaysState = Map<String, IonConnectRelay>;

@Riverpod(keepAlive: true)
class Relay extends _$Relay
    with RelayTimerMixin, RelayCreateMixin, RelayAuthMixin, RelayClosedMixin, RelayActiveMixin {
  @override
  Future<IonConnectRelay> build(String url, {bool anonymous = false}) async {
    try {
      final relay = await createRelay(ref, url);

      final wrappedRelay = RelayLoggingWrapper(relay, logger: ref.read(ionConnectLoggerProvider));

      trackRelayAsActive(wrappedRelay, ref);
      initializeRelayTimer(wrappedRelay, ref);
      initializeRelayClosedListener(wrappedRelay, ref);

      if (!anonymous) {
        await initializeAuth(wrappedRelay, ref);
      }

      ref.onDispose(wrappedRelay.close);

      return wrappedRelay;
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
