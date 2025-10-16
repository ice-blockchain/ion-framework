// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';

mixin RelayClosedMixin {
  StreamSubscription<void>? _subscriptions;

  void initializeRelayClosedListener(IonConnectRelay relay, Ref ref) {
    _subscriptions = relay.onClose.listen((url) {
      ref.invalidateSelf();
    });

    ref.onDispose(() {
      _subscriptions?.cancel();
    });
  }
}
