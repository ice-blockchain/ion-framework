// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/tokenized_communities/models/community_token_buy_request.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_community_token_controller_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_infrastructure_providers.r.dart';
import 'package:ion/app/features/wallets/utils/crypto_amount_converter.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'buy_community_token_notifier_provider.r.g.dart';

@riverpod
class BuyCommunityTokenNotifier extends _$BuyCommunityTokenNotifier {
  @override
  FutureOr<String?> build(String communityPubkey) => null;

  Future<void> buy(UserActionSignerNew signer) async {
    if (state.isLoading) return;

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final formState = ref.read(tradeCommunityTokenControllerProvider(communityPubkey));

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

      const slippagePercent = 1.0;

      final service = await ref.read(tradeCommunityTokenServiceProvider.future);

      final request = CommunityTokenBuyRequest(
        ionConnectAddress: '0:$communityPubkey:',
        amountIn: amountIn,
        slippagePercent: slippagePercent,
        walletId: wallet.id,
        walletAddress: wallet.address!,
        maxFeePerGas: BigInt.from(20000000000), // 20 gwei default
        maxPriorityFeePerGas: BigInt.from(1000000000), // 1 gwei default
        baseTokenAddress: token.contractAddress,
        tokenDecimals: token.decimals,
        userActionSigner: signer,
      );

      return service.performBuy(request);
    });
  }

  Future<BigInt> getBuyQuote({
    required BigInt amountIn,
    required String baseTokenAddress,
  }) async {
    final service = await ref.read(tradeCommunityTokenServiceProvider.future);
    return service.getQuote(
      ionConnectAddress: '0:$communityPubkey:',
      amountIn: amountIn,
      baseTokenAddress: baseTokenAddress,
    );
  }
}
