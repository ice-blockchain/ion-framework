// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:math';

/// MOCK DATA SOURCE: Streams raw JSON data for featured tokens.
/// This simulates API responses that will be parsed by the repository.
class FeaturedTokensDataSourceMock {
  final _random = Random();
  Timer? _timer;

  /// Streams raw JSON data (List<Map<String, dynamic>>) every 1 second.
  Stream<List<Map<String, dynamic>>> subscribeToFeaturedTokens() {
    final controller = StreamController<List<Map<String, dynamic>>>();

    // Initial mock JSON data (5-10 tokens)
    var tokensJson = _generateInitialMockJson();

    // Emit the initial list immediately.
    if (!controller.isClosed) {
      controller.add(tokensJson);
    }

    // Emit random updates every 1 second (full list each time)
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      tokensJson = _applyRandomUpdate(tokensJson);
      if (!controller.isClosed) {
        controller.add(List.unmodifiable(tokensJson));
      }
    });

    return controller.stream;
  }

  void close() {
    _timer?.cancel();
  }

  // HELPER: Generate initial mock JSON tokens
  List<Map<String, dynamic>> _generateInitialMockJson() {
    final count = 5 + _random.nextInt(6); // 5-10 tokens
    final now = DateTime.now();
    const tokenTypes = ['profile', 'post', 'video', 'article'];

    return List.generate(count, (index) {
      return {
        'type': tokenTypes[_random.nextInt(tokenTypes.length)],
        'title': _generateTitle(index),
        'description': _generateDescription(index),
        'imageUrl': 'https://i.pravatar.cc/150?img=${index + 1}',
        'createdAt': now.subtract(Duration(days: _random.nextInt(30))).toIso8601String(),
        'addresses': {
          'blockchain': '0x${_random.nextInt(0xFFFFFFFF).toRadixString(16)}',
          'ionConnect': 'featured-${index + 1}',
        },
        'creator': {
          'name': _mockCreatorName(index),
          'display': _mockCreatorDisplay(index),
          'verified': index % 3 == 0,
          'avatar': 'https://i.pravatar.cc/150?img=${index + 20}',
          'ionConnect': 'creator-${index + 1}',
        },
        'marketData': {
          'marketCap': (_random.nextInt(50000000) + 1000000).toDouble(),
          'volume': (_random.nextInt(5000000) + 10000).toDouble(),
          'holders': _random.nextInt(5000) + 100,
          'priceUSD': _random.nextDouble() * 10 + 0.01,
        },
      };
    });
  }

  // HELPER: Apply random updates to simulate live changes (returns full JSON list)
  List<Map<String, dynamic>> _applyRandomUpdate(List<Map<String, dynamic>> list) {
    final newList = List<Map<String, dynamic>>.from(list);

    // Randomly update market data for some tokens
    for (var i = 0; i < newList.length; i++) {
      if (_random.nextDouble() < 0.3) {
        // 30% chance to update each token
        final token = newList[i];
        final marketData = token['marketData'] as Map<String, dynamic>;
        final currentMarketCap = marketData['marketCap'] as double;
        final currentVolume = marketData['volume'] as double;
        final currentHolders = marketData['holders'] as int;
        final currentPrice = marketData['priceUSD'] as double;

        newList[i] = Map<String, dynamic>.from(token);
        newList[i]['marketData'] = {
          'marketCap': currentMarketCap * (0.95 + _random.nextDouble() * 0.1),
          'volume': currentVolume * (0.9 + _random.nextDouble() * 0.2),
          'holders': (currentHolders * (0.98 + _random.nextDouble() * 0.04)).round(),
          'priceUSD': currentPrice * (0.95 + _random.nextDouble() * 0.1),
        };
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
