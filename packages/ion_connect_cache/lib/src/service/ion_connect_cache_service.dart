// SPDX-License-Identifier: ice License 1.0

import 'package:nostr_dart/nostr_dart.dart';

abstract class IonConnectCacheService {
  Future<EventMessage> save(
    (String masterPubkey, String eventReference, EventMessage eventMessage) value,
  );

  Future<List<EventMessage>> saveAll(
    List<(String masterPubkey, String eventReference, EventMessage eventMessage)> values,
  );

  Future<EventMessage?> get(String eventReference, {Duration? expiration});
  Future<List<EventMessage>> getAll(List<String> eventReferences);
  Future<Set<String>> getAllNonExistingReferences(Set<String> eventReferences);
  Future<List<EventMessage>> getAllFiltered({
    required String query,
    List<int> kinds,
    List<String> eventReferences,
  });

  Stream<List<EventMessage>> watchAll(List<String> eventReferences);

  Future<int> remove(String eventReference);
  Future<int> removeAll(List<String> eventReferences);
  Future<int> clearDatabase();
}
