// SPDX-License-Identifier: ice License 1.0

import 'package:http/http.dart';
import 'package:ion/app/features/config/providers/config_repository.r.dart';
import 'package:ion/app/features/tokenized_communities/blockchain/evm_contract_providers.dart';
import 'package:ion/app/features/tokenized_communities/blockchain/evm_tx_builder.dart';
import 'package:ion/app/features/tokenized_communities/blockchain/ion_identity_transaction_api.dart';
import 'package:ion/app/features/tokenized_communities/data/tokenized_communities_api.dart';
import 'package:ion/app/features/tokenized_communities/domain/tokenized_communities_repository.dart';
import 'package:ion/app/features/tokenized_communities/domain/tokenized_communities_service.dart';
import 'package:ion/app/features/wallets/data/repository/coins_repository.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web3dart/web3dart.dart';

part 'providers.r.g.dart';

@riverpod
Future<TokenizedCommunitiesApi> tokenizedCommunitiesApi(
  Ref ref,
) async {
  final configRepository = await ref.watch(configRepositoryProvider.future);
  return TokenizedCommunitiesApi(
    configRepository: configRepository,
  );
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
Future<List<CoinData>> supportedSwapTokens(Ref ref) async {
  final api = await ref.watch(tokenizedCommunitiesApiProvider.future);
  final supportedTokensConfig = await api.fetchSupportedSwapTokens();
  final coinsRepository = ref.watch(coinsRepositoryProvider);

  final supportedAddresses =
      supportedTokensConfig.map((e) => e['address'] as String).map((e) => e.toLowerCase()).toSet();

  final allCoins = await coinsRepository.getCoins();

  final supportedCoins = allCoins.where((coin) {
    return supportedAddresses.contains(coin.contractAddress.toLowerCase());
  }).toList();

  return supportedCoins;
}
