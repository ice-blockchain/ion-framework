// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_relays_provider.r.g.dart';

@Riverpod(keepAlive: true)
class ActiveRelays extends _$ActiveRelays {
  @override
  Set<String> build() {
    _invalidateOnLogout();
    _invalidateOnSignerChange();
    _invalidateOnUserSwitch();
    return {};
  }

  void addRelay(String url) {
    state = {...state, url};
  }

  void removeRelay(String url) {
    state = {...state}..remove(url);
  }

  void invalidateAll() {
    for (final url in state) {
      ref.invalidate(relayProvider(url));
    }
  }

  void _invalidateOnLogout() {
    onLogout(ref, invalidateAll);
  }

  void _invalidateOnUserSwitch() {
    onUserSwitch(ref, invalidateAll);
  }

  void _invalidateOnSignerChange() {
    ref.listen(
      currentUserIonConnectEventSignerProvider,
      (prev, next) {
        // Only invalidate when switching between two different valid signers
        // This avoids false positives when logging in/out (null transitions)
        final bothNotNull = prev?.value != null && next.value != null;
        final valuesNotEqual = prev?.value != next.value;

        if (bothNotNull && valuesNotEqual) {
          invalidateAll();
        }
      },
    );
  }
}
