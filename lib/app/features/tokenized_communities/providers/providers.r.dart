// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:ion/app/features/config/providers/config_repository.r.dart';
import 'package:ion/app/features/core/providers/wallets_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/blockchain/evm_contract_providers.dart';
import 'package:ion/app/features/tokenized_communities/blockchain/evm_tx_builder.dart';
import 'package:ion/app/features/tokenized_communities/blockchain/ion_identity_transaction_api.dart';
import 'package:ion/app/features/tokenized_communities/data/tokenized_communities_api.dart';
import 'package:ion/app/features/tokenized_communities/domain/tokenized_communities_repository.dart';
import 'package:ion/app/features/tokenized_communities/domain/tokenized_communities_service.dart';
import 'package:ion/app/features/tokenized_communities/models/creator_token_buy_request.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web3dart/web3dart.dart';

part 'providers.r.g.dart';

@riverpod
Future<TokenizedCommunitiesApi> tokenizedCommunitiesApi(
  Ref ref,
) async {
  final configRepository = await ref.watch(configRepositoryProvider.future);
  return TokenizedCommunitiesApi(configRepository: configRepository);
}

@riverpod
EvmContractProviders evmContractProviders(Ref ref) {
  return EvmContractProviders();
}

@riverpod
Web3Client web3Client(Ref ref) {
  // Using the BNB Testnet RPC as requested
  const rpcUrl = 'https://data-seed-prebsc-1-s1.binance.org:8545/';
  final httpClient = Client();
  return Web3Client(rpcUrl, httpClient);
}

@riverpod
EvmTxBuilder evmTxBuilder(Ref ref) {
  final contracts = ref.watch(evmContractProvidersProvider);
  final web3Client = ref.watch(web3ClientProvider);
  return EvmTxBuilder(
    contracts: contracts,
    web3Client: web3Client,
  );
}

@riverpod
IonIdentityTransactionApi ionIdentityTransactionApi(
  Ref ref,
) {
  return IonIdentityTransactionApi(
    clientResolver: () => ref.watch(ionIdentityClientProvider.future),
  );
}

@riverpod
Future<TokenizedCommunitiesRepository> tokenizedCommunitiesRepository(
  Ref ref,
) async {
  final txBuilder = ref.watch(evmTxBuilderProvider);
  final ionIdentity = ref.watch(ionIdentityTransactionApiProvider);
  final api = await ref.watch(tokenizedCommunitiesApiProvider.future);

  return TokenizedCommunitiesRepository(
    txBuilder: txBuilder,
    ionIdentity: ionIdentity,
    api: api,
  );
}

@Riverpod(keepAlive: true)
Future<TokenizedCommunitiesService> tokenizedCommunitiesService(
  Ref ref,
) async {
  final repository = await ref.watch(tokenizedCommunitiesRepositoryProvider.future);

  return TokenizedCommunitiesService(
    repository: repository,
  );
}

@riverpod
// TODO: remove this provider after UI is connected
class BuyCreatorTokenNotifier extends _$BuyCreatorTokenNotifier {
  @override
  FutureOr<String?> build(String creatorPubkey) => null;

  Future<void> performBuy({
    required UserActionSignerNew signer,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final service = await ref.read(tokenizedCommunitiesServiceProvider.future);

      // TODO: Get actual wallet data from providers
      // For now using placeholder values
      // final mainWallet = await ref.watch(mainWalletProvider.future);
      final wallets = await ref.watch(walletsNotifierProvider.future);
      final bscWallet = wallets.firstWhereOrNull((w) => w.network == 'BscTestnet');

      if (bscWallet == null) {
        throw Exception('BscTestnet wallet not found');
      }
      final walletId = bscWallet.id;
      final walletAddress = bscWallet.address;
      const baseTokenAddress = '0x2c73996BaBF1a06c2C057177353293f7cA0907c8';
      final amountIn = BigInt.from(1000000000000000000); // 1 token with 18 decimals
      const slippagePercent = 1.0;
      final maxFeePerGas = BigInt.from(20000000000); // 20 gwei
      final maxPriorityFeePerGas = BigInt.from(1000000000); // 1 gwei

      final request = CreatorTokenBuyRequest(
        ionConnectAddress: '0:$creatorPubkey:',
        amountIn: amountIn,
        slippagePercent: slippagePercent,
        walletId: walletId,
        walletAddress: walletAddress!,
        maxFeePerGas: maxFeePerGas,
        maxPriorityFeePerGas: maxPriorityFeePerGas,
        baseTokenAddress: baseTokenAddress,
        tokenDecimals: 18,
        userActionSigner: signer,
      );

      final txHash = await service.performBuy(request);
      return txHash;
    });
  }
}
