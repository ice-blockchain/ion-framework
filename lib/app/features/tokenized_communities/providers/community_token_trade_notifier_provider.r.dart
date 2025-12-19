// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_community_token_controller_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_infrastructure_providers.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/constants.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/wallets/providers/connected_crypto_wallets_provider.r.dart';
import 'package:ion/app/features/wallets/providers/networks_provider.r.dart';
import 'package:ion/app/features/wallets/utils/crypto_amount_converter.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_token_trade_notifier_provider.r.g.dart';

@riverpod
class CommunityTokenTradeNotifier extends _$CommunityTokenTradeNotifier {
  static const _firstBuyMetadataSentKey = 'community_token_first_buy';

  @override
  FutureOr<String?> build(String externalAddress, ExternalAddressType externalAddressType) => null;

  Future<void> buy(UserActionSignerNew signer) async {
    if (state.isLoading) return;

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final params = (
        externalAddress: externalAddress,
        externalAddressType: externalAddressType,
      );
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

      final response = await service.buyCommunityToken(
        externalAddress: externalAddress,
        externalAddressType: externalAddressType,
        amountIn: amountIn,
        walletId: wallet.id,
        walletAddress: wallet.address!,
        walletNetwork: wallet.network,
        baseTokenAddress: token.contractAddress,
        baseTokenTicker: token.abbreviation,
        tokenDecimals: token.decimals,
        expectedPricing: expectedPricing,
        userActionSigner: signer,
      );
      // Invalidate token market info to refresh balance
      ref.invalidate(
        tokenMarketInfoProvider(externalAddress),
      );

      return response['status'] as String?;
    });
  }

  Future<void> sell(UserActionSignerNew signer) async {
    if (state.isLoading) return;

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final params = (
        externalAddress: externalAddress,
        externalAddressType: externalAddressType,
      );
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

      final tokenInfo = ref.read(tokenMarketInfoProvider(externalAddress)).valueOrNull;
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
        externalAddress: externalAddress,
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
      );

      // Invalidate token market info to refresh balance
      ref.invalidate(
        tokenMarketInfoProvider(externalAddress),
      );

      return response['status'] as String?;
    });
  }

  Future<void> _sendFirstBuyMetadataIfNeeded() async {
    try {
      final userPrefsService = ref.read(currentUserPreferencesServiceProvider);
      if (userPrefsService == null) return;

      final alreadySent = userPrefsService.getValue<bool>(_firstBuyMetadataSentKey) ?? false;
      if (alreadySent) return;

      final currentMetadata = await ref.read(currentUserMetadataProvider.future);
      if (currentMetadata == null) return;

      final networks = await ref.read(networksProvider.future);
      final bscNetwork = networks.firstWhereOrNull((n) => n.isBsc);
      if (bscNetwork == null) return;

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
}
