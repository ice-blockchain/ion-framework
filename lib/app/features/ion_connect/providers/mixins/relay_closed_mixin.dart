// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/logger/websocket_tracker.dart';

mixin RelayClosedMixin {
  StreamSubscription<void>? _subscriptions;

  void initializeRelayClosedListener(IonConnectRelay relay, Ref ref) {
    _subscriptions = relay.onClose.listen((url) {
      // Log WebSocket close
      final socketId = WebSocketTracker.getSocketId(relay);
      final host = WebSocketTracker.getHost(url);
      Logger.info('NOSTR.WS.CLOSE host=$host socket_id=$socketId code=unknown reason=');

      // Cleanup socket tracking
      WebSocketTracker.unregister(relay);

      ref.invalidateSelf();
    });

    ref.onDispose(() {
      _subscriptions?.cancel();
    });
  }
}
