// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/bsc_network_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/fat_address_data_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_operation_protected_accounts_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_community_token_controller_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_infrastructure_providers.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/constants.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/wallets/data/repository/coins_repository.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/providers/connected_crypto_wallets_provider.r.dart';
import 'package:ion/app/features/wallets/providers/update_wallet_view_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_data_sync_coordinator_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/features/wallets/utils/crypto_amount_converter.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_token_trade_notifier_provider.r.g.dart';

typedef CommunityTokenTradeNotifierParams = ({
  String externalAddress,
  ExternalAddressType externalAddressType,
  EventReference? eventReference,
});

@riverpod
class CommunityTokenTradeNotifier extends _$CommunityTokenTradeNotifier {
  static const _firstBuyMetadataSentKey = 'community_token_first_buy';
  static const _broadcastedStatus = 'broadcasted';

  static const _syncWalletDataDelay = Duration(seconds: 3);

  @override
  FutureOr<String?> build(CommunityTokenTradeNotifierParams params) => null;

  Future<void> buy(UserActionSignerNew signer) async {
    if (state.isLoading) return;

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      // Check if this account is protected from token operations
      final protectedAccountsService = ref.read(tokenOperationProtectedAccountsServiceProvider);
      final isProtected = params.eventReference != null
          ? protectedAccountsService.isProtectedAccountEvent(params.eventReference!)
          : protectedAccountsService.isProtectedAccountFromExternalAddress(
              params.externalAddress,
            );
      if (isProtected) {
        throw const TokenOperationProtectedException();
      }

      final formState = ref.read(tradeCommunityTokenControllerProvider(params));

      final token = formState.selectedPaymentToken;
      final wallet = formState.targetWallet;
      final amount = formState.amount;

      if (token == null || wallet == null || amount <= 0) {
        throw StateError('Invalid form state: token, wallet, or amount is missing');
      }

      if (wallet.address == null) {
        Logger.error(
          'Wallet address is missing for wallet ${wallet.id} on network ${wallet.network}',
        );
        throw Exception('Wallet address is missing');
      }

      final amountIn = toBlockchainUnits(amount, token.decimals);
      final service = await ref.read(tradeCommunityTokenServiceProvider.future);
      final expectedPricing = formState.quotePricing;

      if (formState.isQuoting || expectedPricing == null) {
        throw StateError('Quote is not ready yet');
      }

      await _sendFirstBuyMetadataIfNeeded();

      final existingTokenInfo =
          ref.read(tokenMarketInfoProvider(params.externalAddress)).valueOrNull;
      final existingTokenAddress = existingTokenInfo?.addresses.blockchain;
      final fatAddressData = (existingTokenAddress != null && existingTokenAddress.isNotEmpty)
          ? null
          : await ref.read(
              fatAddressDataProvider(
                externalAddress: params.externalAddress,
                externalAddressType: params.externalAddressType,
                eventReference: params.eventReference,
              ).future,
            );

      final response = await service.buyCommunityToken(
        externalAddress: params.externalAddress,
        externalAddressType: params.externalAddressType,
        amountIn: amountIn,
        walletId: wallet.id,
        walletAddress: wallet.address!,
        walletNetwork: wallet.network,
        baseTokenAddress: token.contractAddress,
        baseTokenTicker: token.abbreviation,
        tokenDecimals: token.decimals,
        expectedPricing: expectedPricing,
        fatAddressData: fatAddressData,
        userActionSigner: signer,
        shouldSendEvents: formState.shouldSendEvents,
        slippagePercent: formState.slippage,
      );

      final txHash = _requireBroadcastedTxHash(response);

      try {
        await _importTokenIfNeeded(
          existingTokenAddress,
          formState.communityTokenCoinsGroup,
        );
      } catch (error, stackTrace) {
        Logger.error(
          error,
          stackTrace: stackTrace,
          message: 'Failed to import token',
        );
      }

      unawaited(
        Future.delayed(
          _syncWalletDataDelay,
          () => ref.read(walletDataSyncCoordinatorProvider).syncWalletData(),
        ),
      );

      return txHash;
    });
  }

  Future<void> sell(UserActionSignerNew signer) async {
    if (state.isLoading) return;

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      // Check if this account is protected from token operations
      final protectedAccountsService = ref.read(tokenOperationProtectedAccountsServiceProvider);
      final isProtected = params.eventReference != null
          ? protectedAccountsService.isProtectedAccountEvent(params.eventReference!)
          : protectedAccountsService.isProtectedAccountFromExternalAddress(
              params.externalAddress,
            );
      if (isProtected) {
        throw const TokenOperationProtectedException();
      }

      final formState = ref.read(tradeCommunityTokenControllerProvider(params));

      final token = formState.selectedPaymentToken;
      final wallet = formState.targetWallet;
      final amount = formState.amount;

      if (token == null || wallet == null || amount <= 0) {
        throw StateError('Invalid form state: token, wallet, or amount is missing');
      }

      if (wallet.address == null) {
        Logger.error(
          'Wallet address is missing for wallet ${wallet.id} on network ${wallet.network}',
        );
        throw Exception('Wallet address is missing');
      }

      final tokenInfo = ref.read(tokenMarketInfoProvider(params.externalAddress)).valueOrNull;
      final communityTokenAddress = tokenInfo?.addresses.blockchain;
      if (communityTokenAddress == null || communityTokenAddress.isEmpty) {
        throw StateError('Community token contract address is missing');
      }

      final amountIn =
          toBlockchainUnits(amount, TokenizedCommunitiesConstants.creatorTokenDecimals);
      final service = await ref.read(tradeCommunityTokenServiceProvider.future);
      final expectedPricing = formState.quotePricing;

      if (formState.isQuoting || expectedPricing == null) {
        throw StateError('Quote is not ready yet');
      }

      final response = await service.sellCommunityToken(
        externalAddress: params.externalAddress,
        amountIn: amountIn,
        walletId: wallet.id,
        walletAddress: wallet.address!,
        walletNetwork: wallet.network,
        paymentTokenAddress: token.contractAddress,
        paymentTokenTicker: token.abbreviation,
        paymentTokenDecimals: token.decimals,
        communityTokenAddress: communityTokenAddress,
        tokenDecimals: TokenizedCommunitiesConstants.creatorTokenDecimals,
        expectedPricing: expectedPricing,
        userActionSigner: signer,
        shouldSendEvents: formState.shouldSendEvents,
      );

      final txHash = _requireBroadcastedTxHash(response);

      unawaited(
        ref.read(walletDataSyncCoordinatorProvider).syncWalletData(),
      );
      return txHash;
    });
  }

  String _requireBroadcastedTxHash(Map<String, dynamic> transaction) {
    final status = transaction['status']?.toString() ?? '';
    if (status.isEmpty) {
      throw CommunityTokenTradeTransactionException(
        reason: 'Swap status is missing',
      );
    }

    if (status.toLowerCase() != _broadcastedStatus) {
      throw CommunityTokenTradeTransactionException(
        reason: 'Swap was not broadcasted',
        status: status,
      );
    }

    final txHash = transaction['txHash']?.toString() ?? '';
    if (txHash.isEmpty) {
      throw CommunityTokenTradeTransactionException(
        reason: 'Swap transaction hash is missing',
        status: status,
      );
    }

    return txHash;
  }

  Future<void> _sendFirstBuyMetadataIfNeeded() async {
    try {
      final userPrefsService = ref.read(currentUserPreferencesServiceProvider);
      if (userPrefsService == null) return;

      final alreadySent = userPrefsService.getValue<bool>(_firstBuyMetadataSentKey) ?? false;
      if (alreadySent) return;

      final currentMetadata = await ref.read(currentUserMetadataProvider.future);
      if (currentMetadata == null) return;

      final bscNetwork = await ref.read(bscNetworkDataProvider.future);

      final mainWallets = await ref.read(mainCryptoWalletsProvider.future);
      final bscWallet = mainWallets.firstWhereOrNull(
        (wallet) => wallet.network == bscNetwork.id && wallet.address != null,
      );
      if (bscWallet == null) return;

      final currentWallets = currentMetadata.data.wallets ?? <String, String>{};
      final updatedWallets = Map<String, String>.from(currentWallets);
      if (!updatedWallets.containsKey(bscNetwork.id)) {
        updatedWallets[bscNetwork.id] = bscWallet.address!;
      }

      final updatedMetadata = currentMetadata.data.copyWith(wallets: updatedWallets);
      await ref.read(ionConnectNotifierProvider.notifier).sendEntitiesData([updatedMetadata]);

      await userPrefsService.setValue<bool>(_firstBuyMetadataSentKey, true);
    } catch (error, stackTrace) {
      Logger.error(error, stackTrace: stackTrace, message: 'Failed to send first buy metadata');
    }
  }

  Future<void> _importTokenIfNeeded(
    String? existingTokenAddress,
    CoinsGroup? communityTokenCoinsGroup,
  ) async {
    final tokenData = communityTokenCoinsGroup?.coins.firstOrNull?.coin;
    if (tokenData == null) return;
    if (existingTokenAddress != tokenData.contractAddress) return;

    final ionIdentity = await ref.read(ionIdentityClientProvider.future);

    final coin = await ionIdentity.coins.getCoinData(
      contractAddress: tokenData.contractAddress,
      network: tokenData.network.id,
    );

    final coinData = CoinData.fromDTO(coin, tokenData.network);

    final coinsRepository = ref.read(coinsRepositoryProvider);
    final existingCoin = await coinsRepository.getCoinById(coin.id);
    if (existingCoin != null) return;

    await coinsRepository.updateCoins(
      [
        coinData.toDB(),
      ],
    );

    final currentWalletView = await ref.read(currentWalletViewDataProvider.future);
    final walletCoins =
        currentWalletView.coinGroups.expand((e) => e.coins).map((e) => e.coin).toList();

    final updatedCoins = [...walletCoins, coinData];

    await ref.read(updateWalletViewNotifierProvider.notifier).updateWalletView(
          walletView: currentWalletView,
          updatedCoinsList: updatedCoins,
        );
  }
}
