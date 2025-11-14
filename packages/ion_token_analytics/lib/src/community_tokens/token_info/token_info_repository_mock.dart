// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:ion_token_analytics/src/community_tokens/token_info/models/addresses.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/community_token.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/creator.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/market_data.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/token_info_repository.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class TokenInfoRepositoryMock implements TokenInfoRepository {
  TokenInfoRepositoryMock(this.client);

  final NetworkClient client;
  static final _random = Random();

  static List<CommunityToken> get _mockTokens => [
    CommunityToken(
      type: 'community',
      title: 'Mock Community Token',
      description: 'A mock community token for testing and development',
      imageUrl: 'https://i.pravatar.cc/150?img=10',
      addresses: const Addresses(
        blockchain: '0x1234567890abcdef',
        ionConnect: 'mock_ion_address_1',
      ),
      creator: const Creator(
        name: 'mockCreator',
        display: 'Mock Creator',
        verified: true,
        avatar: 'https://i.pravatar.cc/150?img=1',
        ionConnect: 'mock_creator_address',
      ),
      marketData: MarketData(
        marketCap: _random.nextInt(5000000) + 500000,
        volume: _random.nextInt(1000000) + 100000,
        holders: _random.nextInt(500) + 50,
        priceUSD: _random.nextDouble() * 50 + 0.01,
      ),
    ),
    CommunityToken(
      type: 'community',
      title: 'Test Token 2',
      description: 'Another test token with different market data',
      imageUrl: 'https://i.pravatar.cc/150?img=20',
      addresses: const Addresses(
        blockchain: '0xfedcba0987654321',
        ionConnect: 'mock_ion_address_2',
      ),
      creator: const Creator(
        name: 'testCreator',
        display: 'Test Creator',
        verified: false,
        avatar: 'https://i.pravatar.cc/150?img=2',
        ionConnect: 'test_creator_address',
      ),
      marketData: MarketData(
        marketCap: _random.nextInt(5000000) + 500000,
        volume: _random.nextInt(1000000) + 100000,
        holders: _random.nextInt(500) + 50,
        priceUSD: _random.nextDouble() * 50 + 0.01,
      ),
    ),
    CommunityToken(
      type: 'community',
      title: 'Dev Token',
      description: 'Development token for local testing',
      imageUrl: 'https://i.pravatar.cc/150?img=30',
      addresses: const Addresses(
        blockchain: '0xabcd1234efgh5678',
        ionConnect: 'mock_ion_address_3',
      ),
      creator: const Creator(
        name: 'devCreator',
        display: 'Dev Creator',
        verified: true,
        avatar: 'https://i.pravatar.cc/150?img=3',
        ionConnect: 'dev_creator_address',
      ),
      marketData: MarketData(
        marketCap: _random.nextInt(5000000) + 500000,
        volume: _random.nextInt(1000000) + 100000,
        holders: _random.nextInt(500) + 50,
        priceUSD: _random.nextDouble() * 50 + 0.01,
      ),
    ),
  ];

  @override
  Future<List<CommunityToken>> getTokenInfo(List<String> ionConnectAddresses) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));

    if (_mockTokens.isEmpty) {
      return [];
    }

    return _mockTokens;
  }

  @override
  Future<NetworkSubscription<List<CommunityToken>>> subscribeToTokenInfo(
    List<String> ionConnectAddresses,
  ) async {
    final stream = Stream.periodic(const Duration(seconds: 1), (_) => _mockTokens);

    return NetworkSubscription<List<CommunityToken>>(stream: stream, close: () async {});
  }
}
