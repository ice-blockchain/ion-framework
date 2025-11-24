// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:math';

import 'package:ion_token_analytics/src/community_tokens/token_info/models/models.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class TokenInfoMockHandler {
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

  Future<T> handleGet<T>() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _mockTokens.map((e) => e.toJson()).toList() as T;
  }

  Future<NetworkSubscription<T>> handleSubscription<T>() async {
    final stream = Stream.periodic(const Duration(seconds: 1), (_) {
      // For mock purposes, we can just return the full object as a patch
      // In a real scenario, this would be a partial update
      return _mockTokens.map((e) => e.toJson()).toList() as T;
    });

    return NetworkSubscription(stream: stream, close: () async {});
  }
}
