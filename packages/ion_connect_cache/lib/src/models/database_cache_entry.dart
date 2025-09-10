// SPDX-License-Identifier: ice License 1.0

import 'package:nostr_dart/nostr_dart.dart';

class DatabaseCacheEntry {
  DatabaseCacheEntry({required this.eventMessage, required this.insertedAt});

  final EventMessage eventMessage;
  final DateTime insertedAt;
}
