// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:ion_token_analytics/src/community_tokens/bonding_curve_progress/bonding_curve_progress_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/bonding_curve_progress/bonding_curve_progress_repository_impl.dart';
import 'package:ion_token_analytics/src/community_tokens/category_tokens/category_tokens_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/category_tokens/category_tokens_repository_impl.dart';
import 'package:ion_token_analytics/src/community_tokens/featured_tokens/featured_tokens_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/featured_tokens/featured_tokens_repository_impl.dart';
import 'package:ion_token_analytics/src/community_tokens/global_search_tokens/global_search_tokens_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/global_search_tokens/global_search_tokens_repository_remote.dart';
import 'package:ion_token_analytics/src/community_tokens/latest_tokens/latest_tokens_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/latest_tokens/latest_tokens_repository_impl.dart';
import 'package:ion_token_analytics/src/community_tokens/latest_trades/latest_trades_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/latest_trades/latest_trades_repository_impl.dart';
import 'package:ion_token_analytics/src/community_tokens/ohlcv_candles/ohlcv_candles_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/ohlcv_candles/ohlcv_candles_repository_impl.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/token_info_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/token_info_repository_impl.dart';
import 'package:ion_token_analytics/src/community_tokens/top_holders/top_holders_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/top_holders/top_holders_repository_impl.dart';
import 'package:ion_token_analytics/src/community_tokens/trading_stats/trading_stats_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/trading_stats/trading_stats_repository_impl.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class IonCommunityTokensService {
  IonCommunityTokensService._({
    required TokenInfoRepository tokenInfoRepository,
    required OhlcvCandlesRepository ohlcvCandlesRepository,
    required TradingStatsRepository tradingStatsRepository,
    required TopHoldersRepository topHoldersRepository,
    required LatestTradesRepository latestTradesRepository,
    required FeaturedTokensRepository featuredTokensRepository,
    required LatestTokensRepository latestTokensRepository,
    required CategoryTokensRepository categoryTokensRepository,
    required GlobalSearchTokensRepository globalSearchTokensRepository,
    required BondingCurveProgressRepository bondingCurveProgressRepository,
  }) : _tokenInfoRepository = tokenInfoRepository,
       _ohlcvCandlesRepository = ohlcvCandlesRepository,
       _tradingStatsRepository = tradingStatsRepository,
       _topHoldersRepository = topHoldersRepository,
       _latestTradesRepository = latestTradesRepository,
       _featuredTokensRepository = featuredTokensRepository,
       _latestTokensRepository = latestTokensRepository,
       _categoryTokensRepository = categoryTokensRepository,
       _globalSearchTokensRepository = globalSearchTokensRepository,
       _bondingCurveProgressRepository = bondingCurveProgressRepository;

  final TokenInfoRepository _tokenInfoRepository;
  final OhlcvCandlesRepository _ohlcvCandlesRepository;
  final TradingStatsRepository _tradingStatsRepository;
  final TopHoldersRepository _topHoldersRepository;
  final LatestTradesRepository _latestTradesRepository;
  final FeaturedTokensRepository _featuredTokensRepository;
  final LatestTokensRepository _latestTokensRepository;
  final CategoryTokensRepository _categoryTokensRepository;
  final GlobalSearchTokensRepository _globalSearchTokensRepository;
  final BondingCurveProgressRepository _bondingCurveProgressRepository;

  static Future<IonCommunityTokensService> create({required NetworkClient networkClient}) async {
    final service = IonCommunityTokensService._(
      tokenInfoRepository: TokenInfoRepositoryImpl(networkClient),
      ohlcvCandlesRepository: OhlcvCandlesRepositoryImpl(networkClient),
      tradingStatsRepository: TradingStatsRepositoryImpl(networkClient),
      topHoldersRepository: TopHoldersRepositoryImpl(networkClient),
      latestTradesRepository: LatestTradesRepositoryImpl(networkClient),
      featuredTokensRepository: FeaturedTokensRepositoryImpl(networkClient),
      latestTokensRepository: LatestTokensRepositoryImpl(networkClient),
      categoryTokensRepository: CategoryTokensRepositoryImpl(networkClient),
      globalSearchTokensRepository: GlobalSearchTokensRepositoryRemote(networkClient),
      bondingCurveProgressRepository: BondingCurveProgressRepositoryImpl(networkClient),
    );
    return service;
  }

  Future<CommunityToken?> getTokenInfo(String externalAddress) {
    return _tokenInfoRepository.getTokenInfo(externalAddress);
  }

  Future<NetworkSubscription<CommunityTokenPatch>?> subscribeToTokenInfo(String externalAddress) {
    return _tokenInfoRepository.subscribeToTokenInfo(externalAddress);
  }

  Future<NetworkSubscription<List<OhlcvCandle>>> subscribeToOhlcvCandles({
    required String ionConnectAddress,
    required String interval,
  }) {
    return _ohlcvCandlesRepository.subscribeToOhlcvCandles(
      ionConnectAddress: ionConnectAddress,
      interval: interval,
    );
  }

  Future<NetworkSubscription<Map<String, TradingStats>>> subscribeToTradingStats({
    required String ionConnectAddress,
  }) {
    return _tradingStatsRepository.subscribeToTradingStats(ionConnectAddress);
  }

  Future<NetworkSubscription<List<TopHolderBase>>> subscribeToTopHolders({
    required String ionConnectAddress,
    required int limit,
  }) {
    return _topHoldersRepository.subscribeToTopHolders(ionConnectAddress, limit: limit);
  }

  Future<NetworkSubscription<BondingCurveProgressBase>> subscribeToBondingCurveProgress({
    required String externalAddress,
  }) {
    return _bondingCurveProgressRepository.subscribeToBondingCurveProgress(externalAddress);
  }

  Future<List<LatestTrade>> fetchLatestTrades({
    required String ionConnectAddress,
    int limit = 10,
    int offset = 0,
  }) {
    return _latestTradesRepository.fetchLatestTrades(
      ionConnectAddress,
      limit: limit,
      offset: offset,
    );
  }

  Future<NetworkSubscription<List<LatestTradeBase>>> subscribeToLatestTrades({
    required String ionConnectAddress,
  }) {
    return _latestTradesRepository.subscribeToLatestTrades(ionConnectAddress);
  }

  Future<NetworkSubscription<List<CommunityToken>>> subscribeToFeaturedTokens() {
    return _featuredTokensRepository.subscribeToFeaturedTokens();
  }

  Future<PaginatedCategoryTokensData> getLatestTokens({
    String? keyword,
    String? type,
    int limit = 20,
    int offset = 0,
  }) {
    return _latestTokensRepository.getLatestTokens(
      keyword: keyword,
      type: type,
      limit: limit,
      offset: offset,
    );
  }

  Future<NetworkSubscription<List<CommunityTokenBase>>> subscribeToLatestTokens({
    String? keyword,
    String? type,
  }) {
    return _latestTokensRepository.subscribeToLatestTokens(keyword: keyword, type: type);
  }

  Future<ViewingSession> createViewingSession(TokenCategoryType type) {
    return _categoryTokensRepository.createViewingSession(type);
  }

  Future<PaginatedCategoryTokensData> getCategoryTokens({
    required String sessionId,
    required TokenCategoryType type,
    String? keyword,
    int limit = 20,
    int offset = 0,
  }) {
    return _categoryTokensRepository.getCategoryTokens(
      sessionId: sessionId,
      type: type,
      keyword: keyword,
      limit: limit,
      offset: offset,
    );
  }

  Future<NetworkSubscription<List<CommunityTokenBase>>> subscribeToCategoryTokens({
    required String sessionId,
    required TokenCategoryType type,
  }) {
    return _categoryTokensRepository.subscribeToRealtimeUpdates(sessionId: sessionId, type: type);
  }

  Future<PaginatedCategoryTokensData> getGlobalSearchTokens({
    required List<String> externalAddresses,
    String? keyword,
    int? includeTopPlatformHolders,
    int limit = 20,
    int offset = 0,
  }) {
    return _globalSearchTokensRepository.searchCommunityTokens(
      externalAddresses: externalAddresses,
      keyword: keyword,
      includeTopPlatformHolders: includeTopPlatformHolders,
      limit: limit,
      offset: offset,
    );
  }

  Future<Position?> getHolderPosition(String tokenExternalAddress, String holderExternalAddress) {
    return _tokenInfoRepository.getHolderPosition(tokenExternalAddress, holderExternalAddress);
  }

  Future<PricingResponse?> getPricing(String externalAddress, String type, String amount) {
    return _tokenInfoRepository.getPricing(externalAddress, type, amount);
  }
}
