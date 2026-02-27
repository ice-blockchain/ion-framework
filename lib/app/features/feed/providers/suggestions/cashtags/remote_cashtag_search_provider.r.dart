// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/repository/networks_repository.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remote_cashtag_search_provider.r.g.dart';

@riverpod
Future<List<CoinData>> remoteCashtagSearch(Ref ref, String keyword) async {
  if (keyword.isEmpty) return [];

  final ionIdentityClient = await ref.watch(ionIdentityClientProvider.future);
  final results = await ionIdentityClient.coins.searchCoins(keyword: keyword);

  final networksRepository = ref.read(networksRepositoryProvider);
  final networks = await networksRepository.getAllAsMap();

  return results.map((coin) {
    final network = networks[coin.network];
    if (network == null) {
      // Create a minimal NetworkData for coins whose network isn't locally cached.
      // Only ticker, icon, and externalAddress are needed for the cashtag suggestion UI.
      return CoinData.fromDTO(
        coin,
        NetworkData(
          id: coin.network,
          image: '',
          isTestnet: false,
          displayName: coin.network,
          explorerUrl: '',
          tier: 0,
        ),
      );
    }
    return CoinData.fromDTO(coin, network);
  }).toList();
}
