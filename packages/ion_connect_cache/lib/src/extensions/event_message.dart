// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:nostr_dart/nostr_dart.dart';

extension KeysExtensions on EventMessage {
  String? get masterPubkey {
    final masterPubkey = tags.firstWhereOrNull((tags) => tags[0] == 'b')?.elementAtOrNull(1);

    return masterPubkey;
  }
}
