// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/category_tokens/category_tokens_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/category_tokens/category_tokens_repository_impl.dart';
import 'package:ion_token_analytics/src/community_tokens/featured_tokens/featured_tokens_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/featured_tokens/featured_tokens_repository_impl.dart';
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
  factory IonCommunityTokensService.create({required NetworkClient networkClient}) {
    final service = IonCommunityTokensService._(
      tokenInfoRepository: TokenInfoRepositoryImpl(networkClient),
      ohlcvCandlesRepository: OhlcvCandlesRepositoryImpl(networkClient),
      tradingStatsRepository: TradingStatsRepositoryImpl(networkClient),
      topHoldersRepository: TopHoldersRepositoryImpl(networkClient),
      latestTradesRepository: LatestTradesRepositoryImpl(networkClient),
      featuredTokensRepository: FeaturedTokensRepositoryImpl(networkClient),
      latestTokensRepository: LatestTokensRepositoryImpl(networkClient),
      categoryTokensRepository: CategoryTokensRepositoryImpl(networkClient),
    );
    return service;
  }
  IonCommunityTokensService._({
    required this.tokenInfoRepository,
    required this.ohlcvCandlesRepository,
    required this.tradingStatsRepository,
    required this.topHoldersRepository,
    required this.latestTradesRepository,
    required this.featuredTokensRepository,
    required this.latestTokensRepository,
    required this.categoryTokensRepository,
  });

  final TokenInfoRepository tokenInfoRepository;
  final OhlcvCandlesRepository ohlcvCandlesRepository;
  final TradingStatsRepository tradingStatsRepository;
  final TopHoldersRepository topHoldersRepository;
  final LatestTradesRepository latestTradesRepository;
  final FeaturedTokensRepository featuredTokensRepository;
  final LatestTokensRepository latestTokensRepository;
  final CategoryTokensRepository categoryTokensRepository;
}
