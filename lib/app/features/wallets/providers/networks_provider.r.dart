// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/repository/networks_repository.r.dart';
import 'package:ion/app/features/wallets/domain/networks/networks_comparator.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'networks_provider.r.g.dart';

@riverpod
Future<List<NetworkData>> networks(Ref ref) {
  return ref
      .watch(networksRepositoryProvider)
      .getAll()
      .then((networks) => networks.sortedBy((a) => a.displayName));
}

@riverpod
Future<List<NetworkData>> networksByTier(Ref ref, {required int tier}) {
  return ref
      .watch(networksRepositoryProvider)
      .getByFilters(tiers: [tier]).then((networks) => networks.sortedBy((a) => a.displayName));
}

@riverpod
Future<List<NetworkData>> networksWithNft(Ref ref) {
  final comparator = NetworksComparator(sortType: NetworkSortType.nftPopularity);
  return ref
      .watch(networksRepositoryProvider)
      .getNftNetworks()
      .then((networks) => networks.sorted(comparator.compareNetworks));
}

@riverpod
Future<NetworkData?> networkById(Ref ref, String id) {
  return ref.watch(networksRepositoryProvider).getById(id);
}
