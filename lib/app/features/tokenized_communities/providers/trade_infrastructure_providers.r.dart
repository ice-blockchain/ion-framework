// SPDX-License-Identifier: ice License 1.0

import 'package:http/http.dart';
import 'package:ion/app/features/config/providers/config_repository.r.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/blockchain/evm_contract_providers.dart';
import 'package:ion/app/features/tokenized_communities/blockchain/evm_tx_builder.dart';
import 'package:ion/app/features/tokenized_communities/blockchain/ion_identity_transaction_api.dart';
import 'package:ion/app/features/tokenized_communities/data/trade_community_token_api.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_community_token_repository.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_community_token_service.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_ion_connect_notifier_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/wallets/data/repository/coins_repository.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web3dart/web3dart.dart';

part 'trade_infrastructure_providers.r.g.dart';

@riverpod
Future<TradeCommunityTokenApi> tradeCommunityTokenApi(
  Ref ref,
) async {
  final configRepository = await ref.watch(configRepositoryProvider.future);
  final analyticsClient = await ref.watch(ionTokenAnalyticsClientProvider.future);
  return TradeCommunityTokenApi(
    configRepository: configRepository,
    analyticsClient: analyticsClient,
  );
}

@riverpod
EvmContractProviders evmContractProviders(Ref ref) {
  return EvmContractProviders();
}

@riverpod
Web3Client web3Client(Ref ref) {
  // Using the BNB Testnet RPC as requested
  final rpcUrl =
      ref.watch(envProvider.notifier).get<String>(EnvVariable.CRYPTOCURRENCIES_BSC_RPC_URL);
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
Future<TradeCommunityTokenRepository> tradeCommunityTokenRepository(
  Ref ref,
) async {
  final txBuilder = ref.watch(evmTxBuilderProvider);
  final ionIdentity = ref.watch(ionIdentityTransactionApiProvider);
  final api = await ref.watch(tradeCommunityTokenApiProvider.future);

  return TradeCommunityTokenRepository(
    txBuilder: txBuilder,
    ionIdentity: ionIdentity,
    api: api,
  );
}

@Riverpod(keepAlive: true)
Future<TradeCommunityTokenService> tradeCommunityTokenService(
  Ref ref,
) async {
  final repository = await ref.watch(tradeCommunityTokenRepositoryProvider.future);
  final ionConnectService = await ref.watch(communityTokenIonConnectServiceProvider.future);

  return TradeCommunityTokenService(
    repository: repository,
    ionConnectService: ionConnectService,
  );
}

@riverpod
Future<List<CoinData>> supportedSwapTokens(Ref ref) async {
  final api = await ref.watch(tradeCommunityTokenApiProvider.future);
  final supportedTokensConfig = await api.fetchSupportedSwapTokens();
  final coinsRepository = ref.watch(coinsRepositoryProvider);

  final supportedAddresses =
      supportedTokensConfig.map((e) => e['address'] as String).map((e) => e.toLowerCase()).toSet();

  final supportedCoins = await coinsRepository.getCoinsByFilters(
    contractAddresses: supportedAddresses,
  );

  return supportedCoins;
}

@riverpod
Future<CommunityToken> communityTokenInfo(
  Ref ref,
  String externalAddress,
) async {
  final token = await ref.watch(tokenMarketInfoProvider(externalAddress).future);

  if (token == null) {
    throw Exception('Token info not found for $externalAddress');
  }
  return token;
}
