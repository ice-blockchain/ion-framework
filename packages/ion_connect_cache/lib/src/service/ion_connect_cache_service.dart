// SPDX-License-Identifier: ice License 1.0

import 'package:ion_connect_cache/src/models/database_cache_entry.dart';
import 'package:nostr_dart/nostr_dart.dart';

abstract class IonConnectCacheService {
  Future<EventMessage?> save(({String cacheKey, EventMessage eventMessage}) value);
  Future<List<EventMessage>> saveAll(List<({String cacheKey, EventMessage eventMessage})> values);

  Future<DatabaseCacheEntry?> get(String cacheKey);
  Future<List<DatabaseCacheEntry>> getAllFiltered({
    String? keyword,
    List<int> kinds = const [],
    List<String> cacheKeys = const [],
  });

  Stream<DatabaseCacheEntry?> watch(String cacheKey);
  Stream<List<DatabaseCacheEntry>> watchAll({
    String? keyword,
    List<int> kinds = const [],
    List<String> cacheKeys = const [],
  });

  Future<int> remove(String cacheKey);
  Future<int> removeAll({
    String? keyword,
    List<int> kinds = const [],
    List<String> cacheKeys = const [],
    List<String> masterPubkeys = const [],
  });

  Future<int> clearDatabase();
}
