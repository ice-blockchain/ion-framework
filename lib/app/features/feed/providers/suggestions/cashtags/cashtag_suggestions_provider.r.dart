// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/wallets/data/repository/networks_repository.r.dart';
import 'package:ion/app/features/wallets/domain/coins/search_coins_service.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coin_in_wallet_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cashtag_suggestions_provider.r.g.dart';

@riverpod
Future<List<CoinsGroup>> cashtagSuggestions(Ref ref, String query) async {
  if (query.isEmpty || !query.startsWith(r'$')) {
    return [];
  }

  final searchQuery = query.substring(1).trim();
  if (searchQuery.isEmpty) return [];

  final origin = ref.read(envProvider.notifier).get<String>(EnvVariable.ION_ORIGIN);
  if (!origin.contains('staging')) {
    return _fallbackToLocalSearch(ref, searchQuery);
  }

  try {
    final identityClient = await ref.watch(ionIdentityClientProvider.future);
    final coins = await identityClient.coins.searchCoins(keyword: searchQuery);
    final networksMap = await ref.read(networksRepositoryProvider).getAllAsMap();
    final groups = _mapApiCoinsToGroups(coins, networksMap);
    if (groups.isEmpty) {
      return _fallbackToLocalSearch(ref, searchQuery);
    }
    return groups.map((g) => g.copyWith(abbreviation: g.abbreviation.toUpperCase())).toList();
  } on CurrentUserNotFoundException {
    return _fallbackToLocalSearch(ref, searchQuery);
  } catch (_) {
    return _fallbackToLocalSearch(ref, searchQuery);
  }
}

List<CoinsGroup> _mapApiCoinsToGroups(
  List<Coin> coins,
  Map<String, NetworkData> networksMap,
) {
  final grouped = coins.groupListsBy((c) => c.symbolGroup);
  return grouped.entries.map((entry) {
    final symbolGroup = entry.key;
    final list = entry.value;
    final first = list.first;

    final validCoins = list.where((c) => networksMap[c.network] != null).toList();
    if (validCoins.isEmpty) {
      return CoinsGroup(
        name: first.name,
        symbolGroup: symbolGroup,
        abbreviation: first.symbol.toUpperCase(),
        coins: [],
        iconUrl: first.iconURL,
      );
    }

    final coinsList = validCoins.map((c) {
      final n = networksMap[c.network]!;
      return CoinInWalletData(coin: CoinData.fromDTO(c, n));
    }).toList();
    return CoinsGroup(
      name: first.name,
      symbolGroup: symbolGroup,
      abbreviation: first.symbol.toUpperCase(),
      coins: coinsList,
      iconUrl: first.iconURL,
    );
  }).toList();
}

Future<List<CoinsGroup>> _fallbackToLocalSearch(Ref ref, String searchQuery) async {
  final searchService = ref.read(searchCoinsServiceProvider);
  final coinsGroups = await searchService.search(searchQuery.toLowerCase());
  return coinsGroups.take(10).toList();
}
