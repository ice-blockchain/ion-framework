// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:math';

import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:ion_token_analytics/src/community_tokens/featured_tokens/featured_tokens_repository.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

/// MOCK REPOSITORY: Streams a list of featured CommunityTokens with periodic updates.
class FeaturedTokensRepositoryMock implements FeaturedTokensRepository {
  final _random = Random();
  Timer? _timer;

  @override
  Future<NetworkSubscription<List<CommunityToken>>> subscribeToFeaturedTokens() async {
    final controller = StreamController<List<CommunityToken>>();

    // Initial mock data (5-10 tokens)
    var tokens = _generateInitialMockTokens();

    // Emit the initial list immediately.
    if (!controller.isClosed) {
      controller.add(tokens);
    }

    // Emit random updates every 3-5 seconds (full list each time)
    _timer = Timer.periodic(Duration(seconds: 3 + Random().nextInt(3)), (timer) {
      tokens = _applyRandomUpdate(tokens);
      if (!controller.isClosed) {
        controller.add(List.unmodifiable(tokens));
      }
    });

    return NetworkSubscription<List<CommunityToken>>(
      stream: controller.stream,
      close: () async {
        _timer?.cancel();
        await controller.close();
      },
    );
  }

  // HELPER: Generate initial mock tokens
  List<CommunityToken> _generateInitialMockTokens() {
    final count = 5 + _random.nextInt(6); // 5-10 tokens
    final now = DateTime.now();

    return List.generate(count, (index) {
      return CommunityToken(
        type: 'featured',
        title: _generateTitle(index),
        description: _generateDescription(index),
        imageUrl: 'https://i.pravatar.cc/150?img=${index + 1}',
        createdAt: now.subtract(Duration(days: _random.nextInt(30))).toIso8601String(),
        addresses: Addresses(
          blockchain: '0x${_random.nextInt(0xFFFFFFFF).toRadixString(16)}',
          ionConnect: 'featured-${index + 1}',
        ),
        creator: Creator(
          name: _mockCreatorName(index),
          display: _mockCreatorDisplay(index),
          verified: index % 3 == 0,
          avatar: 'https://i.pravatar.cc/150?img=${index + 20}',
          ionConnect: 'creator-${index + 1}',
        ),
        marketData: MarketData(
          marketCap: (_random.nextInt(50000000) + 1000000).toDouble(),
          volume: (_random.nextInt(5000000) + 10000).toDouble(),
          holders: _random.nextInt(5000) + 100,
          priceUSD: _random.nextDouble() * 10 + 0.01,
        ),
      );
    });
  }

  // HELPER: Apply random updates to simulate live changes (returns full list)
  List<CommunityToken> _applyRandomUpdate(List<CommunityToken> list) {
    final newList = List<CommunityToken>.from(list);

    // Randomly update market data for some tokens
    for (var i = 0; i < newList.length; i++) {
      if (_random.nextDouble() < 0.3) {
        // 30% chance to update each token
        final token = newList[i];
        newList[i] = token.copyWith(
          marketData: token.marketData.copyWith(
            marketCap: token.marketData.marketCap * (0.95 + _random.nextDouble() * 0.1),
            volume: token.marketData.volume * (0.9 + _random.nextDouble() * 0.2),
            holders: (token.marketData.holders * (0.98 + _random.nextDouble() * 0.04)).round(),
            priceUSD: token.marketData.priceUSD * (0.95 + _random.nextDouble() * 0.1),
          ),
        );
      }
    }

    return newList;
  }

  String _generateTitle(int index) {
    const titles = [
      'Featured Token 1',
      'Featured Token 2',
      'Featured Token 3',
      'Featured Token 4',
      'Featured Token 5',
      'Featured Token 6',
      'Featured Token 7',
      'Featured Token 8',
    ];
    return titles[index % titles.length];
  }

  String _generateDescription(int index) {
    const descriptions = [
      'This is an amazing featured token that everyone should check out.',
      'A great example of a quality community token.',
      'Trending now and gaining popularity rapidly.',
      'Highly recommended by the community.',
      'One of the best featured tokens available.',
    ];
    return descriptions[index % descriptions.length];
  }

  String _mockCreatorName(int index) {
    const names = [
      'susanheller',
      'johnsmith',
      'alicej',
      'bobw',
      'emmad',
      'chrisb',
      'sarahk',
      'mikej',
    ];
    return names[index % names.length];
  }

  String _mockCreatorDisplay(int index) {
    const displays = [
      'Susan V. Heller',
      'John Smith',
      'Alice Johnson',
      'Bob Williams',
      'Emma Davis',
      'Chris Brown',
      'Sarah Kim',
      'Mike Johnson',
    ];
    return displays[index % displays.length];
  }
}
