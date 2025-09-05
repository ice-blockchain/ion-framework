// SPDX-License-Identifier: ice License 1.0

import 'package:ion_connect_cache/src/models/database_cache_entry.dart';
import 'package:nostr_dart/nostr_dart.dart';

abstract class IonConnectCacheService {
  Future<EventMessage> save(
    ({String masterPubkey, String eventReference, EventMessage eventMessage}) value,
  );

  Future<List<EventMessage>> saveAll(
    List<({String masterPubkey, String eventReference, EventMessage eventMessage})> values,
  );

  Future<DatabaseCacheEntry?> get(String eventReference);
  Future<List<DatabaseCacheEntry?>> getAll(List<String> eventReferences);
  Future<List<DatabaseCacheEntry?>> getAllFiltered({
    required String keyword,
    List<int> kinds = const [],
    List<String> eventReferences = const [],
  });

  Stream<List<EventMessage>> watchAll(List<String> eventReferences);

  Future<int> remove(String eventReference);
  Future<int> removeAll(List<String> eventReferences);
  Future<int> clearDatabase();
}
