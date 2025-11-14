// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_relay_provider.r.g.dart';

@Riverpod(keepAlive: true)
class SelectedRelay extends _$SelectedRelay {
  static const String _selectedRelayKey = 'selectedRelayUrl';

  @override
  String? build() {
    return ref.read(localStorageProvider).getString(_selectedRelayKey);
  }

  Future<void> setSelectedRelay(String? relayUrl) async {
    if (relayUrl == null) {
      await ref.read(localStorageProvider).remove(_selectedRelayKey);
      state = null;
    } else {
      await ref.read(localStorageProvider).setString(_selectedRelayKey, relayUrl);
      state = relayUrl;
    }
  }

  Future<void> clearSelectedRelay() async {
    await setSelectedRelay(null);
  }
}

