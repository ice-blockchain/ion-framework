// SPDX-License-Identifier: ice License 1.0

import 'package:ion_connect_cache/src/models/database_cache_entry.dart';
import 'package:nostr_dart/nostr_dart.dart';

typedef IonConnectCacheServiceEntity = ({String cacheKey, EventMessage eventMessage});

abstract class IonConnectCacheService {
  Future<EventMessage?> save(IonConnectCacheServiceEntity value);
  Future<List<EventMessage>> saveAll(List<IonConnectCacheServiceEntity> values);

  Future<DatabaseCacheEntry?> get(String cacheKey);
  Future<List<DatabaseCacheEntry>> getAllFiltered({
    String? keyword,
    List<int>? kinds,
    List<String>? cacheKeys,
    List<String>? masterPubkeys,
  });

  Stream<DatabaseCacheEntry?> watch(String cacheKey);
  Stream<List<DatabaseCacheEntry>> watchAll({
    String? keyword,
    List<int>? kinds,
    List<String>? cacheKeys,
    List<String>? masterPubkeys,
  });

  Future<int> remove(String cacheKey);
  Future<int> removeAll({
    String? keyword,
    List<int>? kinds,
    List<String>? cacheKeys,
    List<String>? masterPubkeys,
  });

  Future<int> clearDatabase();
}
