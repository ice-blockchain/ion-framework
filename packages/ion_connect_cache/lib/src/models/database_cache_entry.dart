// SPDX-License-Identifier: ice License 1.0

import 'package:meta/meta.dart';
import 'package:nostr_dart/nostr_dart.dart';

@immutable
class DatabaseCacheEntry {
  const DatabaseCacheEntry({required this.eventMessage, required this.insertedAt});

  final EventMessage eventMessage;
  final DateTime insertedAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DatabaseCacheEntry) return false;
    return eventMessage.id == other.eventMessage.id &&
        insertedAt.millisecondsSinceEpoch == other.insertedAt.millisecondsSinceEpoch;
  }

  @override
  int get hashCode => Object.hash(eventMessage.id, insertedAt.millisecondsSinceEpoch);
}
