// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:ion_token_analytics/src/community_tokens/ohlcv_candles/ohlcv_candles_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/ohlcv_candles/ohlcv_candles_repository_mock.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/token_info_repository.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/token_info_repository_mock.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class IonCommunityTokensService {
  IonCommunityTokensService._({
    required TokenInfoRepository tokenInfoRepository,
    required OhlcvCandlesRepository ohlcvCandlesRepository,
  }) : _tokenInfoRepository = tokenInfoRepository,
       _ohlcvCandlesRepository = ohlcvCandlesRepository;

  final TokenInfoRepository _tokenInfoRepository;
  final OhlcvCandlesRepository _ohlcvCandlesRepository;

  static Future<IonCommunityTokensService> create({required NetworkClient networkClient}) async {
    final service = IonCommunityTokensService._(
      tokenInfoRepository: TokenInfoRepositoryMock(networkClient),
      ohlcvCandlesRepository: OhlcvCandlesRepositoryMock(),
    );
    return service;
  }

  Future<List<CommunityToken>> getTokenInfo(List<String> ionConnectAddresses) {
    return _tokenInfoRepository.getTokenInfo(ionConnectAddresses);
  }

  Future<NetworkSubscription<List<CommunityToken>>> subscribeToTokenInfo(
    List<String> ionConnectAddresses,
  ) {
    return _tokenInfoRepository.subscribeToTokenInfo(ionConnectAddresses);
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
}
