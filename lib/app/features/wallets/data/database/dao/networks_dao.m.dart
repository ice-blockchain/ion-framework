// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/database/tables/networks_table.d.dart';
import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'networks_dao.m.g.dart';

@Riverpod(keepAlive: true)
NetworksDao networksDao(Ref ref) => NetworksDao(db: ref.watch(walletsDatabaseProvider));

@DriftAccessor(tables: [NetworksTable])
class NetworksDao extends DatabaseAccessor<WalletsDatabase> with _$NetworksDaoMixin {
  NetworksDao({required WalletsDatabase db}) : super(db);

  Future<void> insertAll(List<Network> networks) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(networksTable, networks);
    });
  }

  Future<void> setAll(List<Network> networks) async {
    await transaction(() async {
      await delete(networksTable).go();
      await batch((batch) {
        batch.insertAll(networksTable, networks);
      });
    });
  }

  Future<List<Network>> getAll() {
    return select(networksTable).get();
  }

  Stream<List<Network>> watchNetworks() {
    return select(networksTable).watch();
  }

  Future<Network?> getById(String id) {
    final query = select(networksTable)
      ..where((t) => t.id.equals(id))
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<bool> hasAny() async {
    final query = select(networksTable)..limit(1);
    final result = await query.get();
    return result.isNotEmpty;
  }

  Future<List<Network>> getByFilters({required List<int> tiers}) {
    final query = select(networksTable);

    if (tiers.isNotEmpty) {
      query.where((t) => t.tier.isIn(tiers));
    }

    return query.get();
  }
}
