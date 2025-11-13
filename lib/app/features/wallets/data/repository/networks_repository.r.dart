// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/database/dao/networks_dao.m.dart';
import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart' as db;
import 'package:ion/app/features/wallets/domain/networks/network_mapper.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'networks_repository.r.g.dart';

@Riverpod(keepAlive: true)
NetworksRepository networksRepository(Ref ref) => NetworksRepository(
      networksDao: ref.watch(networksDaoProvider),
    );

class NetworksRepository {
  NetworksRepository({
    required NetworksDao networksDao,
  }) : _networksDao = networksDao;

  final NetworksDao _networksDao;

  Future<NetworkData?> getById(String id) {
    return _networksDao.getById(id).then((network) {
      if (network == null) return null;
      return NetworkData.fromDB(network);
    });
  }

  Future<void> save(List<NetworkData> networks) {
    final dbNetworks = NetworksMapper().toDb(networks);
    return _networksDao.insertAll(dbNetworks);
  }

  Future<void> setAll(List<NetworkData> networks) {
    final dbNetworks = NetworksMapper().toDb(networks);
    return _networksDao.setAll(dbNetworks);
  }

  Future<List<NetworkData>> getByFilters({List<int> tiers = const []}) {
    return _networksDao.getByFilters(tiers: tiers).then((networks) => networks.toConvertedList());
  }

  Future<List<NetworkData>> getNftNetworks() => getByFilters(tiers: [1]).then(
        (networks) => networks.where((network) => !network.isTon).toList(),
      );

  Future<List<NetworkData>> getAll() {
    return _networksDao.getAll().then((networks) => networks.toConvertedList());
  }

  Stream<List<NetworkData>> watchAll() {
    return _networksDao.watchNetworks().map((networks) => networks.toConvertedList());
  }

  Future<Map<String, NetworkData>> getAllAsMap() =>
      _networksDao.getAll().then((networks) => networks.toConvertedMap());

  Future<bool> hasAny() => _networksDao.hasAny();
}

extension NetworksListConverter on List<db.Network> {
  List<NetworkData> toConvertedList() {
    return map(NetworkData.fromDB).toList();
  }

  Map<String, NetworkData> toConvertedMap() => {
        for (final network in this) network.id: NetworkData.fromDB(network),
      };
}
