// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/config/providers/config_repository.r.dart';
import 'package:ion/app/features/tokenized_communities/blockchain/evm_contract_providers.dart';
import 'package:ion/app/features/tokenized_communities/blockchain/evm_tx_builder.dart';
import 'package:ion/app/features/tokenized_communities/blockchain/ion_identity_transaction_api.dart';
import 'package:ion/app/features/tokenized_communities/data/token_info_cache.dart';
import 'package:ion/app/features/tokenized_communities/data/trade_community_token_api.dart';
import 'package:ion/app/features/tokenized_communities/domain/supported_swap_tokens_resolver_service.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_community_token_repository.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_community_token_service.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_payment_token_groups_service.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_ion_connect_notifier_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_operation_protected_accounts_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/web3client_provider.r.dart';
import 'package:ion/app/features/wallets/data/repository/coins_repository.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trade_infrastructure_providers.r.g.dart';

@riverpod
Future<SupportedSwapTokensResolverService> supportedSwapTokensResolverService(Ref ref) async {
  return SupportedSwapTokensResolverService(
    coinsRepository: ref.watch(coinsRepositoryProvider),
    ionIdentityClient: await ref.watch(ionIdentityClientProvider.future),
  );
}

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

  final tokenInfoCache = TokenInfoCache(loader: api.fetchTokenInfo);

  return TradeCommunityTokenRepository(
    txBuilder: txBuilder,
    ionIdentity: ionIdentity,
    api: api,
    tokenInfoCache: tokenInfoCache,
  );
}

@riverpod
Future<TradeCommunityTokenService> tradeCommunityTokenService(
  Ref ref,
) async {
  final repository = await ref.watch(tradeCommunityTokenRepositoryProvider.future);
  final ionConnectService = await ref.watch(communityTokenIonConnectServiceProvider.future);
  final protectedAccountsService = ref.watch(tokenOperationProtectedAccountsServiceProvider);

  return TradeCommunityTokenService(
    repository: repository,
    ionConnectService: ionConnectService,
    protectedAccountsService: protectedAccountsService,
  );
}

@riverpod
Future<String> bondingCurveAddress(Ref ref) async {
  final repository = await ref.watch(tradeCommunityTokenRepositoryProvider.future);
  return repository.fetchBondingCurveAddress();
}

@riverpod
Future<List<CoinData>> supportedSwapTokens(Ref ref) async {
  final api = await ref.watch(tradeCommunityTokenApiProvider.future);
  final supportedTokensConfig = await api.fetchSupportedSwapTokens();
  final supportedTokensResolver =
      await ref.watch(supportedSwapTokensResolverServiceProvider.future);

  final resolvedCoins = await supportedTokensResolver.resolveFromConfig(supportedTokensConfig);
  if (resolvedCoins.isNotEmpty) return resolvedCoins;

  final currentWalletView = await ref.watch(currentWalletViewDataProvider.future);
  return supportedTokensResolver.resolveFromWalletViewFallback(
    supportedTokensConfig: supportedTokensConfig,
    walletViewCoins: currentWalletView.coins.map((e) => e.coin),
  );
}

@riverpod
TradePaymentTokenGroupsService tradePaymentTokenGroupsService(Ref ref) {
  return const TradePaymentTokenGroupsService();
}

@riverpod
Future<List<CoinsGroup>> supportedSwapTokenGroups(Ref ref) async {
  final (tokens, walletView) = await (
    ref.watch(supportedSwapTokensProvider.future),
    ref.watch(currentWalletViewDataProvider.future),
  ).wait;

  final service = ref.watch(tradePaymentTokenGroupsServiceProvider);
  return service.build(
    supportedTokens: tokens,
    walletView: walletView,
  );
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
