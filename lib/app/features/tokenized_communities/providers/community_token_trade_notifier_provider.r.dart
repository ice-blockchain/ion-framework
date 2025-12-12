// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/tokenized_communities/enums/community_token_trade_mode.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_community_token_controller_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_infrastructure_providers.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/constants.dart';
import 'package:ion/app/features/wallets/utils/crypto_amount_converter.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_token_trade_notifier_provider.r.g.dart';

@riverpod
class CommunityTokenTradeNotifier extends _$CommunityTokenTradeNotifier {
  @override
  FutureOr<String?> build(String externalAddress, CommunityTokenType type) => null;

  Future<void> buy(UserActionSignerNew signer) async {
    if (state.isLoading) return;

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final params = (
        externalAddress: externalAddress,
        type: type,
        mode: CommunityTokenTradeMode.buy,
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

      final amountIn =
          toBlockchainUnits(amount, TokenizedCommunitiesConstants.creatorTokenDecimals);
      final service = await ref.read(tradeCommunityTokenServiceProvider.future);

      final response = await service.buyCommunityToken(
        externalAddress: externalAddress,
        type: type,
        amountIn: amountIn,
        walletId: wallet.id,
        walletAddress: wallet.address!,
        baseTokenAddress: token.contractAddress,
        tokenDecimals: TokenizedCommunitiesConstants.creatorTokenDecimals,
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
        type: type,
        mode: CommunityTokenTradeMode.sell,
      );
      final formState = ref.read(tradeCommunityTokenControllerProvider(params));

      final token = formState.selectedPaymentToken;
      final wallet = formState.targetWallet;
      final amount = formState.amount;
      final communityTokenCoinsGroup = formState.communityTokenCoinsGroup;

      if (token == null || wallet == null || amount <= 0) {
        throw StateError('Invalid form state: token, wallet, or amount is missing');
      }

      if (wallet.address == null) {
        Logger.error(
          'Wallet address is missing for wallet ${wallet.id} on network ${wallet.network}',
        );
        throw Exception('Wallet address is missing');
      }

      if (communityTokenCoinsGroup == null || communityTokenCoinsGroup.coins.isEmpty) {
        throw StateError('Community token coins group is missing');
      }

      final communityTokenCoin = communityTokenCoinsGroup.coins.first.coin;
      final communityTokenAddress = communityTokenCoin.contractAddress;

      final amountIn =
          toBlockchainUnits(amount, TokenizedCommunitiesConstants.creatorTokenDecimals);
      final service = await ref.read(tradeCommunityTokenServiceProvider.future);

      final response = await service.sellCommunityToken(
        externalAddress: externalAddress,
        amountIn: amountIn,
        walletId: wallet.id,
        walletAddress: wallet.address!,
        paymentTokenAddress: token.contractAddress,
        communityTokenAddress: communityTokenAddress,
        tokenDecimals: TokenizedCommunitiesConstants.creatorTokenDecimals,
        userActionSigner: signer,
      );

      // Invalidate token market info to refresh balance
      ref.invalidate(
        tokenMarketInfoProvider(externalAddress),
      );

      return response['status'] as String?;
    });
  }
}
