// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:ion_token_analytics/src/community_tokens/latest_trades/latest_trades_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/latest_trades/latest_trades_repository_impl.dart';
import 'package:ion_token_analytics/src/community_tokens/ohlcv_candles/ohlcv_candles_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/ohlcv_candles/ohlcv_candles_repository_impl.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/token_info_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/token_info_repository_mock.dart';
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
  }) : _tokenInfoRepository = tokenInfoRepository,
       _ohlcvCandlesRepository = ohlcvCandlesRepository,
       _tradingStatsRepository = tradingStatsRepository,
       _topHoldersRepository = topHoldersRepository,
       _latestTradesRepository = latestTradesRepository;

  final TokenInfoRepository _tokenInfoRepository;
  final OhlcvCandlesRepository _ohlcvCandlesRepository;
  final TradingStatsRepository _tradingStatsRepository;
  final TopHoldersRepository _topHoldersRepository;
  final LatestTradesRepository _latestTradesRepository;

  static Future<IonCommunityTokensService> create({required NetworkClient networkClient}) async {
    // Base URL doesn't matter for mock

    final service = IonCommunityTokensService._(
      tokenInfoRepository: TokenInfoRepositoryMock(networkClient),
      ohlcvCandlesRepository: OhlcvCandlesRepositoryImpl(networkClient),
      tradingStatsRepository: TradingStatsRepositoryImpl(networkClient),
      topHoldersRepository: TopHoldersRepositoryImpl(networkClient),
      latestTradesRepository: LatestTradesRepositoryImpl(networkClient),
    );
    return service;
  }

  Future<List<CommunityToken>> getTokenInfo(List<String> ionConnectAddresses) {
    return _tokenInfoRepository.getTokenInfo(ionConnectAddresses);
  }

  Future<NetworkSubscription<List<CommunityToken>>> subscribeToTokenInfo(List<String> ionConnectAddresses) {
    return _tokenInfoRepository.subscribeToTokenInfo(ionConnectAddresses);
  }

  Future<NetworkSubscription<List<OhlcvCandle>>> subscribeToOhlcvCandles({
    required String ionConnectAddress,
    required String interval,
  }) {
    return _ohlcvCandlesRepository.subscribeToOhlcvCandles(ionConnectAddress: ionConnectAddress, interval: interval);
  }

  Future<NetworkSubscription<Map<String, TradingStats>>> subscribeToTradingStats({required String ionConnectAddress}) {
    return _tradingStatsRepository.subscribeToTradingStats(ionConnectAddress);
  }

  Future<NetworkSubscription<List<TopHolder>>> subscribeToTopHolders({
    required String ionConnectAddress,
    required int limit,
  }) {
    return _topHoldersRepository.subscribeToTopHolders(ionConnectAddress, limit: limit);
  }

  Future<List<LatestTrade>> fetchLatestTrades({required String ionConnectAddress, int limit = 10, int offset = 0}) {
    return _latestTradesRepository.fetchLatestTrades(ionConnectAddress, limit: limit, offset: offset);
  }

  Future<NetworkSubscription<LatestTradePatch>> subscribeToLatestTrades({required String ionConnectAddress}) {
    return _latestTradesRepository.subscribeToLatestTrades(ionConnectAddress);
  }
}
