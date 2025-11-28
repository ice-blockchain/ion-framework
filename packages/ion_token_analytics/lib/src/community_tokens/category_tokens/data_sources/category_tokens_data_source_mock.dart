// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:math';

// Mock data source for category tokens (trending/top/latest).
// Returns raw JSON data that simulates REST API and WebSocket responses.
class CategoryTokensDataSourceMock {
  final _random = Random();
  final List<Timer> _realtimeTimers = [];
  final Map<String, List<Map<String, dynamic>>> _mockDataCache = {};

  // Creates a viewing session for the given category type.
  // Returns JSON: {"id": "session-id", "ttl": 3600000}
  Future<Map<String, dynamic>> createViewingSession(String type) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    return {'id': 'mock-viewing-session-${DateTime.now().millisecondsSinceEpoch}', 'ttl': 3600000};
  }

  // Fetches a page of category tokens via REST API.
  // Returns flat array of full token objects.
  // Repository will calculate hasMore based on response.length == limit.
  Future<List<Map<String, dynamic>>> getCategoryTokens({
    required String sessionId,
    required String type,
    String? keyword,
    int limit = 20,
    int offset = 0,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));

    final cacheKey = '$sessionId:$type:${keyword ?? ''}';
    final allTokens = _mockDataCache[cacheKey] ??= _generateMockTokens(type, keyword);

    final endIndex = (offset + limit).clamp(0, allTokens.length);
    final pageTokens = allTokens.sublist(offset.clamp(0, allTokens.length), endIndex);

    return pageTokens;
  }

  // Subscribes to real-time updates via WebSocket.
  // Returns stream of single Map objects:
  // - Randomly sends updates OR new items (full token object)
  // Updates format: {addresses: {ionConnect: "..."}, marketData: {...}} (partial, matches full structure)
  // New items format: full token object
  Stream<Map<String, dynamic>> subscribeToRealtimeUpdates({
    required String sessionId,
    required String type,
  }) {
    final controller = StreamController<Map<String, dynamic>>();
    final prefix = type == 'trending'
        ? 'trending'
        : type == 'top'
        ? 'top'
        : 'latest';

    // For trending/top: send new items every 2 seconds (for testing)
    // For latest: keep original behavior (updates or new items every 15 seconds)
    const interval = Duration(seconds: 2);

    final timer = Timer.periodic(interval, (timer) {
      if (controller.isClosed) {
        timer.cancel();
        _realtimeTimers.remove(timer);
        return;
      }

      // Randomly send updates (40%) or new items (60%)
      final scenario = _random.nextInt(10);
      if (scenario < 4) {
        // 40% chance: send update for existing item
        final update = _generateUpdate(type, prefix);
        controller.add(update);
      } else {
        // 60% chance: send new item
        final newItem = _generateNewItem(type, prefix);
        controller.add(newItem);
      }
    });
    _realtimeTimers.add(timer);

    return controller.stream;
  }

  // Fetches a page of latest tokens via REST API (no viewing session).
  // Returns flat array of full token objects.
  // Repository will calculate hasMore based on response.length == limit.
  Future<List<Map<String, dynamic>>> getLatestTokens({
    String? keyword,
    String? type,
    int limit = 20,
    int offset = 0,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));

    final cacheKey = 'latest:${type ?? ''}:${keyword ?? ''}';
    final allTokens = _mockDataCache[cacheKey] ??= _generateMockTokens('latest', keyword);

    final endIndex = (offset + limit).clamp(0, allTokens.length);
    final pageTokens = allTokens.sublist(offset.clamp(0, allTokens.length), endIndex);

    return pageTokens;
  }

  // Subscribes to real-time updates for latest tokens via WebSocket (no viewing session).
  // Returns stream of single Map objects:
  // - Randomly sends updates OR new items (full token object)
  // Updates format: {addresses: {ionConnect: "..."}, marketData: {...}} (partial, matches full structure)
  // New items format: full token object
  Stream<Map<String, dynamic>> subscribeToLatestRealtimeUpdates({String? keyword, String? type}) {
    final controller = StreamController<Map<String, dynamic>>();

    final timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (controller.isClosed) {
        timer.cancel();
        _realtimeTimers.remove(timer);
        return;
      }

      final scenario = _random.nextInt(2);

      if (scenario == 0) {
        final update = _generateUpdate('latest', 'latest');
        controller.add(update);
      } else {
        final newItem = _generateNewItem('latest', 'latest');
        controller.add(newItem);
      }
    });
    _realtimeTimers.add(timer);

    return controller.stream;
  }

  // Closes the real-time subscription and cancels all timers.
  void close() {
    for (final timer in _realtimeTimers) {
      timer.cancel();
    }
    _realtimeTimers.clear();
  }

  // Generates mock token data for initial load and pagination.
  // Filters by searchQuery if provided.
  List<Map<String, dynamic>> _generateMockTokens(String type, String? searchQuery) {
    final count = 50 + _random.nextInt(50);
    final now = DateTime.now();
    final prefix = type == 'trending'
        ? 'trending'
        : type == 'top'
        ? 'top'
        : 'latest';

    return List.generate(count, (index) {
      final name = _mockCreatorName(index);
      final display = _mockCreatorDisplay(index);

      if (searchQuery != null &&
          !name.toLowerCase().contains(searchQuery.toLowerCase()) &&
          !display.toLowerCase().contains(searchQuery.toLowerCase())) {
        return null;
      }

      return {
        'type': 'community',
        'title': '$prefix Token ${index + 1}',
        'description': _generateDescription(index),
        'imageUrl': 'https://i.pravatar.cc/150?img=${index + 1}',
        'createdAt': now.subtract(Duration(days: _random.nextInt(30))).toIso8601String(),
        'addresses': {
          'blockchain': '0x${_random.nextInt(0xFFFFFFFF).toRadixString(16)}',
          'ionConnect': '$prefix-${index + 1}',
        },
        'creator': {
          'name': name,
          'display': display,
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
    }).whereType<Map<String, dynamic>>().toList();
  }

  // Generates a partial update JSON for an existing token.
  // Returns: {addresses: {ionConnect: "..."}, marketData: {...}} with only changed fields.
  // Matches the full token structure exactly.
  Map<String, dynamic> _generateUpdate(String type, String prefix) {
    final existingIndex = _random.nextInt(50);
    final ionConnect = '$prefix-${existingIndex + 1}';

    final updateType = _random.nextInt(3);
    if (updateType == 0) {
      return {
        'addresses': {'ionConnect': ionConnect},
        'marketData': {'priceUSD': _random.nextDouble() * 10 + 0.01},
      };
    } else if (updateType == 1) {
      return {
        'addresses': {'ionConnect': ionConnect},
        'marketData': {
          'marketCap': (_random.nextInt(50000000) + 1000000).toDouble(),
          'volume': (_random.nextInt(5000000) + 10000).toDouble(),
        },
      };
    } else {
      return {
        'addresses': {'ionConnect': ionConnect},
        'marketData': {
          'holders': _random.nextInt(5000) + 100,
          'priceUSD': _random.nextDouble() * 10 + 0.01,
        },
      };
    }
  }

  // Generates a full new token object for real-time additions.
  Map<String, dynamic> _generateNewItem(String type, String prefix) {
    final now = DateTime.now();
    final i = 1000 + _random.nextInt(1000);

    return {
      'type': 'community',
      'title': '$prefix Token $i (NEW)',
      'description': 'Newly added token',
      'imageUrl': 'https://i.pravatar.cc/150?img=$i',
      'createdAt': now.toIso8601String(),
      'addresses': {
        'blockchain': '0x${_random.nextInt(0xFFFFFFFF).toRadixString(16)}',
        'ionConnect': '$prefix-new-$i',
      },
      'creator': {
        'name': _mockCreatorName(i),
        'display': _mockCreatorDisplay(i),
        'verified': i % 3 == 0,
        'avatar': 'https://i.pravatar.cc/150?img=${i + 20}',
        'ionConnect': 'creator-new-$i',
      },
      'marketData': {
        'marketCap': (_random.nextInt(50000000) + 1000000).toDouble(),
        'volume': (_random.nextInt(5000000) + 10000).toDouble(),
        'holders': _random.nextInt(5000) + 100,
        'priceUSD': _random.nextDouble() * 10 + 0.01,
      },
    };
  }

  // Helper: Generates a mock description for a token.
  String _generateDescription(int index) {
    const descriptions = [
      'A popular community token gaining traction.',
      'Trending now with strong community support.',
      'One of the top performing tokens this week.',
      'Highly recommended by the community.',
      'Great token with active trading.',
    ];
    return descriptions[index % descriptions.length];
  }

  // Helper: Generates a mock creator username.
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

  // Helper: Generates a mock creator display name.
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
