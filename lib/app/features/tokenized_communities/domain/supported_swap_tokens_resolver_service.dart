// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/tokenized_communities/data/models/supported_swap_token_config_dto.f.dart';
import 'package:ion/app/features/wallets/data/repository/coins_repository.r.dart';
import 'package:ion/app/features/wallets/domain/coins/coins_mapper.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_identity_client/ion_identity.dart';

class SupportedSwapTokensResolverService {
  SupportedSwapTokensResolverService({
    required CoinsRepository coinsRepository,
    required IONIdentityClient ionIdentityClient,
  })  : _coinsRepository = coinsRepository,
        _ionIdentityClient = ionIdentityClient;

  final CoinsRepository _coinsRepository;
  final IONIdentityClient _ionIdentityClient;

  Future<List<CoinData>> resolveFromConfig(
    List<SupportedSwapTokenConfigDto> supportedTokensConfig,
  ) async {
    final entries = _entriesFromConfig(supportedTokensConfig);
    if (entries.isEmpty) return const [];

    final requestedAddresses = entries.map((e) => e.address).toSet();
    final requestedNetworks = entries.map((e) => e.network).toSet();

    final initialCoins = await _coinsRepository.getCoinsByFilters(
      contractAddresses: requestedAddresses,
      networks: requestedNetworks,
    );

    final initialCoinsByKey = _coinsByKey(initialCoins);
    final missing = entries.where((e) => !initialCoinsByKey.containsKey(e.key)).toList();
    if (missing.isEmpty) {
      return _orderedCoins(entries: entries, coinsByKey: initialCoinsByKey);
    }

    final fetched = await _fetchMissingCoins(missing);

    if (fetched.isNotEmpty) {
      await _coinsRepository.updateCoins(
        CoinsMapper().fromDtoToDb(fetched),
      );
    }

    final resolvedCoins = await _coinsRepository.getCoinsByFilters(
      contractAddresses: requestedAddresses,
      networks: requestedNetworks,
    );
    return _orderedCoins(
      entries: entries,
      coinsByKey: _coinsByKey(resolvedCoins),
    );
  }

  List<CoinData> resolveFromWalletViewFallback({
    required List<SupportedSwapTokenConfigDto> supportedTokensConfig,
    required Iterable<CoinData> walletViewCoins,
  }) {
    final entries = _entriesFromConfig(supportedTokensConfig);
    if (entries.isEmpty) return const [];

    final walletViewCoinsByKey = _coinsByKey(walletViewCoins);
    return _orderedCoins(entries: entries, coinsByKey: walletViewCoinsByKey);
  }

  Future<List<Coin>> _fetchMissingCoins(List<_SupportedSwapTokenEntry> missing) async {
    final results = await Future.wait(
      missing.map(_fetchCoinDataOrNull),
    );
    return results.whereType<Coin>().toList();
  }

  Future<Coin?> _fetchCoinDataOrNull(_SupportedSwapTokenEntry entry) async {
    try {
      return await _ionIdentityClient.coins.getCoinData(
        contractAddress: entry.address,
        network: entry.network,
      );
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message:
            '[SupportedSwapTokensResolverService] Failed to fetch coin data | network=${entry.network} address=${entry.address}',
      );
      return null;
    }
  }

  List<_SupportedSwapTokenEntry> _entriesFromConfig(
    List<SupportedSwapTokenConfigDto> supportedTokensConfig,
  ) {
    return supportedTokensConfig.map(_SupportedSwapTokenEntry.fromConfigOrNull).nonNulls.toList();
  }

  Map<String, CoinData> _coinsByKey(Iterable<CoinData> coins) {
    return Map<String, CoinData>.fromEntries(
      coins.map((coin) => MapEntry(_coinKey(coin), coin)),
    );
  }

  List<CoinData> _orderedCoins({
    required List<_SupportedSwapTokenEntry> entries,
    required Map<String, CoinData> coinsByKey,
  }) {
    return [
      for (final entry in entries)
        if (coinsByKey[entry.key] case final CoinData coin) coin,
    ];
  }

  String _coinKey(CoinData coin) {
    return '${coin.network.id.toLowerCase()}|${coin.contractAddress.trim().toLowerCase()}';
  }
}

class _SupportedSwapTokenEntry {
  const _SupportedSwapTokenEntry({
    required this.network,
    required this.address,
  });

  static _SupportedSwapTokenEntry? fromConfigOrNull(SupportedSwapTokenConfigDto entry) {
    final network = entry.network.trim();
    final address = entry.address.trim();
    if (network.isEmpty || address.isEmpty) return null;
    return _SupportedSwapTokenEntry(network: network, address: address);
  }

  final String network;
  final String address;

  String get key => '${network.toLowerCase()}|${address.toLowerCase()}';
}
