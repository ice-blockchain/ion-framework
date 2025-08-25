// SPDX-License-Identifier: ice License 1.0

import 'package:nostr_dart/nostr_dart.dart';

abstract class IonConnectCacheService {
  Future<EventMessage> put(EventMessage eventMessage);
  Future<EventMessage> get(String id);
  Future<int> remove(String id);
  Future<int> clearDatabase();
}
