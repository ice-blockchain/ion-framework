// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/utils/constants.dart';
import 'package:ion/app/features/wallets/data/repository/networks_repository.r.dart';
import 'package:ion/app/features/wallets/domain/coins/coins_service.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class MoneyMessageCoinResolver {
  const MoneyMessageCoinResolver({
    required CoinsService coinsService,
    required NetworksRepository networksRepository,
    required IONIdentityClient ionIdentityClient,
    required IonTokenAnalyticsClient tokenAnalyticsClient,
  })  : _coinsService = coinsService,
        _networksRepository = networksRepository,
        _ionIdentityClient = ionIdentityClient,
        _tokenAnalyticsClient = tokenAnalyticsClient;

  final CoinsService _coinsService;
  final NetworksRepository _networksRepository;
  final IONIdentityClient _ionIdentityClient;
  final IonTokenAnalyticsClient _tokenAnalyticsClient;

  Future<CoinData?> resolve({
    required String? assetId,
    required String networkId,
    required String assetAddress,
  }) async {
    final normalizedContractAddress = assetAddress.toLowerCase();
    if (normalizedContractAddress.isEmpty) {
      return null;
    }

    final byId = await _coinsService.getCoinById(assetId.emptyOrValue);
    if (byId != null) return byId;

    final network = await _networksRepository.getById(networkId);
    if (network == null) return null;

    final byLocalContract = await _resolveByLocalContract(network, normalizedContractAddress);
    if (byLocalContract != null) return byLocalContract;

    final byCoinsBackend = await _resolveByCoinsBackend(network, normalizedContractAddress);
    if (byCoinsBackend != null) return byCoinsBackend;

    return _resolveByTokenAnalytics(
      network,
      normalizedContractAddress,
      assetId: assetId,
    );
  }

  Future<CoinData?> _resolveByLocalContract(
    NetworkData network,
    String normalizedContractAddress,
  ) async {
    final candidates = await _coinsService.getCoinsByFilters(
      network: network,
      contractAddress: normalizedContractAddress,
    );

    return candidates.firstWhereOrNull(
      (coin) => coin.contractAddress.toLowerCase() == normalizedContractAddress,
    );
  }

  Future<CoinData?> _resolveByCoinsBackend(
    NetworkData network,
    String normalizedContractAddress,
  ) async {
    try {
      final dtoCoin = await _ionIdentityClient.coins.getCoinData(
        contractAddress: normalizedContractAddress,
        network: network.id,
      );
      return CoinData.fromDTO(dtoCoin, network);
    } catch (_) {
      return null;
    }
  }

  Future<CoinData?> _resolveByTokenAnalytics(
    NetworkData network,
    String normalizedContractAddress, {
    required String? assetId,
  }) async {
    final externalAddress = assetId?.trim();
    if (externalAddress == null || externalAddress.isEmpty) {
      return null;
    }

    try {
      final tokenInfo = await _tokenAnalyticsClient.communityTokens.getTokenInfo(externalAddress);
      if (tokenInfo == null) {
        return null;
      }

      final blockchainAddress = tokenInfo.addresses.blockchain?.trim().toLowerCase();
      if (blockchainAddress != null &&
          blockchainAddress.isNotEmpty &&
          blockchainAddress != normalizedContractAddress) {
        return null;
      }

      final title = tokenInfo.title.trim().isEmpty ? externalAddress : tokenInfo.title.trim();

      return CoinData(
        id: externalAddress,
        contractAddress: normalizedContractAddress,
        decimals: TokenizedCommunitiesConstants.creatorTokenDecimals,
        iconUrl: tokenInfo.imageUrl ?? '',
        name: title,
        network: network,
        priceUSD: tokenInfo.marketData.priceUSD,
        abbreviation: title,
        symbolGroup: title,
        syncFrequency: const Duration(hours: 1),
      );
    } on Object {
      return null;
    }
  }
}
