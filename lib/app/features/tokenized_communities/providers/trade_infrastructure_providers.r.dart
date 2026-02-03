// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:ion/app/features/config/providers/config_repository.r.dart';
import 'package:ion/app/features/tokenized_communities/blockchain/evm_contract_providers.dart';
import 'package:ion/app/features/tokenized_communities/blockchain/evm_tx_builder.dart';
import 'package:ion/app/features/tokenized_communities/blockchain/ion_identity_transaction_api.dart';
import 'package:ion/app/features/tokenized_communities/data/pancakeswap_v3_repository.dart';
import 'package:ion/app/features/tokenized_communities/data/token_info_cache.dart';
import 'package:ion/app/features/tokenized_communities/data/trade_community_token_api.dart';
import 'package:ion/app/features/tokenized_communities/domain/pancakeswap_v3_service.dart';
import 'package:ion/app/features/tokenized_communities/domain/pancakeswap_v3_user_ops_builder.dart';
import 'package:ion/app/features/tokenized_communities/domain/supported_swap_tokens_resolver_service.dart';
import 'package:ion/app/features/tokenized_communities/domain/tokenized_communities_trade_config.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_community_token_repository.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_community_token_service.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_ops_support.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_payment_token_groups_service.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_quote_builder.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_route_builder.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_token_resolver.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_user_ops_builder.dart';
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
PancakeSwapV3Repository pancakeSwapV3Repository(Ref ref) {
  final web3Client = ref.watch(web3ClientProvider);
  return PancakeSwapV3Repository(
    web3Client: web3Client,
    tradeConfig: _tradeConfig(),
  );
}

@riverpod
PancakeSwapV3Service pancakeSwapV3Service(Ref ref) {
  final repository = ref.watch(pancakeSwapV3RepositoryProvider);
  return PancakeSwapV3Service(
    repository: repository,
    tradeConfig: _tradeConfig(),
  );
}

@riverpod
PancakeSwapV3UserOpsBuilder pancakeSwapV3UserOpsBuilder(Ref ref) {
  final pancakeSwapService = ref.watch(pancakeSwapV3ServiceProvider);
  return PancakeSwapV3UserOpsBuilder(
    pancakeSwapService: pancakeSwapService,
  );
}

@riverpod
Future<TradeCommunityTokenService> tradeCommunityTokenService(
  Ref ref,
) async {
  final repository = await ref.watch(tradeCommunityTokenRepositoryProvider.future);
  final ionConnectService = await ref.watch(communityTokenIonConnectServiceProvider.future);
  final protectedAccountsService = ref.watch(tokenOperationProtectedAccountsServiceProvider);
  final pancakeSwapService = ref.watch(pancakeSwapV3ServiceProvider);
  final pancakeSwapUserOpsBuilder = ref.watch(pancakeSwapV3UserOpsBuilderProvider);
  final tokenResolver = TradeTokenResolver(tradeConfig: _tradeConfig());
  final support = TradeOpsSupport(repository: repository);
  final routeBuilder = TradeRouteBuilder(tokenResolver: tokenResolver);
  final quoteBuilder = TradeQuoteBuilder(
    repository: repository,
    pancakeSwapService: pancakeSwapService,
    support: support,
  );
  final userOpsBuilder = TradeUserOpsBuilder(
    repository: repository,
    pancakeSwapService: pancakeSwapService,
    pancakeSwapUserOpsBuilder: pancakeSwapUserOpsBuilder,
    support: support,
    tradeConfig: _tradeConfig(),
  );

  return TradeCommunityTokenService(
    repository: repository,
    ionConnectService: ionConnectService,
    protectedAccountsService: protectedAccountsService,
    routeBuilder: routeBuilder,
    quoteBuilder: quoteBuilder,
    userOpsBuilder: userOpsBuilder,
  );
}

TokenizedCommunitiesTradeConfig _tradeConfig() {
  return const TokenizedCommunitiesTradeConfig(
    pancakeSwapWbnbAddress: '0xae13d989dac2f0debff460ac112a837c89baa7cd',
    pancakeSwapIonTokenAddress: '0x2c73996babf1a06c2c057177353293f7ca0907c8',
    pancakeSwapSwapRouterAddress: '0x1b81D678ffb9C0263b24A97847620C99d213eB14',
    pancakeSwapQuoterV2Address: '0xbC203d7f83677c7ed3F7acEc959963E7F4ECC5C2',
    pancakeSwapFeeTier: 500,
    ionTokenDecimals: 18,
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

  final currentWalletView = await ref.watch(currentWalletViewDataProvider.future);
  final walletViewCoins = currentWalletView.coins.map((e) => e.coin);

  final resolvedCoins = await supportedTokensResolver.resolveFromConfig(supportedTokensConfig);
  final resolvedWithBnb = _ensureBnbSwapToken(
    coins: resolvedCoins,
    walletViewCoins: walletViewCoins,
  );
  if (resolvedWithBnb.isNotEmpty) return resolvedWithBnb;

  final fallbackCoins = supportedTokensResolver.resolveFromWalletViewFallback(
    supportedTokensConfig: supportedTokensConfig,
    walletViewCoins: walletViewCoins,
  );

  return _ensureBnbSwapToken(
    coins: fallbackCoins,
    walletViewCoins: walletViewCoins,
  );
}

// TODO(ion): Remove when supported swap tokens config includes BNB explicitly.
List<CoinData> _ensureBnbSwapToken({
  required List<CoinData> coins,
  required Iterable<CoinData> walletViewCoins,
}) {
  if (coins.any(_isBnbCoin)) return coins;
  final bnbCoin = walletViewCoins.firstWhereOrNull(_isBnbCoin);
  if (bnbCoin == null) return coins;
  return [...coins, bnbCoin];
}

bool _isBnbCoin(CoinData coin) {
  return coin.network.isBsc && (coin.native || coin.abbreviation.toUpperCase() == 'BNB');
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
