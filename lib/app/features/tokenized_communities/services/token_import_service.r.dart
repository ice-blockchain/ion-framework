// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/core/providers/wallets_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_infrastructure_providers.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/creator_token_utils.dart';
import 'package:ion/app/features/wallets/data/repository/coins_repository.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/providers/networks_provider.r.dart';
import 'package:ion/app/features/wallets/providers/update_wallet_view_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/utils/retry.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_import_service.r.g.dart';

@riverpod
TokenImportService tokenImportService(Ref ref) {
  return TokenImportService(
    ref: ref,
  );
}

class TokenImportService {
  TokenImportService({
    required Ref ref,
  }) : _ref = ref;

  final Ref _ref;

  Future<void> importTokenIfNeeded({
    required String externalAddress,
    String? existingTokenAddress,
    CoinsGroup? communityTokenCoinsGroup,
  }) async {
    final tokenData = communityTokenCoinsGroup?.coins.firstOrNull?.coin;

    String? contractAddress;
    NetworkData? network;

    if (tokenData != null) {
      contractAddress = tokenData.contractAddress;
      network = tokenData.network;
    } else if (existingTokenAddress == null || existingTokenAddress.isEmpty) {
      // First buy - token was just created, need to fetch the address
      // Get network from BSC wallet first
      final wallets = _ref.read(walletsNotifierProvider).valueOrNull ?? [];
      final bscWallet = CreatorTokenUtils.findBscWallet(wallets);
      if (bscWallet == null) {
        return;
      }
      network = await _ref.read(networkByIdProvider(bscWallet.network).future);
      if (network == null) {
        return;
      }

      // Try to get token address from tokenMarketInfoProvider (might be updated via stream)
      final tokenInfo = _ref.read(tokenMarketInfoProvider(externalAddress)).valueOrNull;
      contractAddress = tokenInfo?.addresses.blockchain;

      // If still null or empty, retry fetching with fresh data (token might be propagating)
      if (contractAddress == null || contractAddress.isEmpty) {
        try {
          final service = await _ref.read(tradeCommunityTokenServiceProvider.future);
          contractAddress = await withRetry<String>(
            ({Object? error}) async {
              final freshTokenInfo = await service.fetchTokenInfoFresh(externalAddress);
              final tokenAddress = freshTokenInfo?.addresses.blockchain;
              if (tokenAddress == null || tokenAddress.isEmpty) {
                throw TokenAddressNotFoundException(externalAddress);
              }
              return tokenAddress;
            },
            maxRetries: 5,
            initialDelay: const Duration(milliseconds: 500),
            maxDelay: const Duration(seconds: 2),
            retryWhen: (error) => error is TokenAddressNotFoundException,
          );
          // After successful retry, contractAddress is guaranteed to be non-null and non-empty
        } catch (error, stackTrace) {
          Logger.error(
            error,
            stackTrace: stackTrace,
            message: '[TokenImportService] Failed to fetch token address after first buy',
          );
          return;
        }
      }

      // Verify contractAddress is not empty (it's already non-null if we reach here)
      if (contractAddress.isEmpty) {
        return;
      }
    } else {
      // Not a first buy, but tokenData is null - this shouldn't happen
      return;
    }

    // At this point, contractAddress and network are guaranteed to be non-null
    // (either from tokenData or successfully fetched in first-buy path)

    // Only skip import if existingTokenAddress exists and doesn't match.
    // For first buy (existingTokenAddress is null/empty), we should proceed with import.
    final shouldSkip = existingTokenAddress != null &&
        existingTokenAddress.isNotEmpty &&
        existingTokenAddress.toLowerCase() != contractAddress.toLowerCase();

    if (shouldSkip) {
      return;
    }

    final ionIdentity = await _ref.read(ionIdentityClientProvider.future);

    final coin = await ionIdentity.coins.getCoinData(
      contractAddress: contractAddress,
      network: network.id,
    );

    final coinData = CoinData.fromDTO(coin, network);

    final coinsRepository = _ref.read(coinsRepositoryProvider);
    final existingCoin = await coinsRepository.getCoinById(coin.id);
    if (existingCoin != null) return;

    await coinsRepository.updateCoins(
      [
        coinData.toDB(),
      ],
    );

    final currentWalletView = await _ref.read(currentWalletViewDataProvider.future);
    final walletCoins =
        currentWalletView.coinGroups.expand((e) => e.coins).map((e) => e.coin).toList();

    final updatedCoins = [...walletCoins, coinData];

    await _ref.read(updateWalletViewNotifierProvider.notifier).updateWalletView(
          walletView: currentWalletView,
          updatedCoinsList: updatedCoins,
        );
  }
}
