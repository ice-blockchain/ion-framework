// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:nostr_dart/nostr_dart.dart';

extension KeysExtensions on EventMessage {
  String? get masterPubkey {
    // For 10100 (user delegation) events, the master pubkey is stored in the pubkey field
    // because this event doesn't have delegation
    final masterPubkey = kind == 10100
        ? pubkey
        : tags.firstWhereOrNull((tags) => tags[0] == 'b')?.elementAtOrNull(1);

    return masterPubkey;
  }
}
