// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:math';

import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class LatestTradesMockHandler {
  final _random = Random();

  Future<T> handleGet<T>(int limit) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final trades = _generateInitialMockTrades(limit);
    // Return as List<dynamic> (JSON) because the repository expects that
    return trades.map((e) => e.toJson()).toList() as T;
  }

  Future<NetworkSubscription<T>> handleSubscription<T>() async {
    final controller = StreamController<T>();

    // Helper to add to controller safely
    void addToController(dynamic event) {
      if (!controller.isClosed) {
        controller.add(event as T);
      }
    }

    // Emit random updates every 2-3 seconds.
    final updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final trade = _generateRandomTrade();
      addToController(trade.toJson());
    });

    return NetworkSubscription<T>(
      stream: controller.stream,
      close: () async {
        updateTimer.cancel();
        await controller.close();
      },
    );
  }

  // --- Mock Data Generation Logic ---

  List<LatestTrade> _generateInitialMockTrades(int count) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return List.generate(count, (index) {
      final side = _random.nextBool() ? 'buy' : 'sell';
      final minutesAgo = (index + 1) * 5;
      return LatestTrade(
        creator: Creator(
          name: 'creator${index + 1}',
          display: 'Creator ${index + 1}',
          verified: true,
          avatar: 'https://i.pravatar.cc/150?img=${index + 10}',
          ionConnect: 'creator-${index + 1}',
        ),
        position: TradePosition(
          holder: Creator(
            name: 'trader${index + 1}',
            display: _mockName(index + 1),
            verified: (index + 1) % 3 == 0,
            avatar: 'https://i.pravatar.cc/150?img=${index + 1}',
            ionConnect: 'trader-${index + 1}',
          ),
          addresses: Addresses(
            blockchain: '0x${_random.nextInt(0xFFFFFFFF).toRadixString(16)}',
            ionConnect: 'trader-${index + 1}',
          ),
          createdAt: DateTime.fromMillisecondsSinceEpoch(now - (minutesAgo * 60 * 1000)).toIso8601String(),
          type: side,
          amount: 100.0 + _random.nextDouble() * 1000.0,
          amountUSD: 5.0 + _random.nextDouble() * 500.0,
          balance: 200.0 + _random.nextDouble() * 2000.0,
          balanceUSD: 10.0 + _random.nextDouble() * 1000.0,
        ),
      );
    });
  }

  LatestTrade _generateRandomTrade() {
    final now = DateTime.now();
    final side = _random.nextBool() ? 'buy' : 'sell';
    return LatestTrade(
      creator: Creator(
        name: 'creator${_random.nextInt(100)}',
        display: 'Creator ${_random.nextInt(100)}',
        verified: true,
        avatar: 'https://i.pravatar.cc/150?img=${_random.nextInt(50) + 10}',
        ionConnect: 'creator-${_random.nextInt(100)}',
      ),
      position: TradePosition(
        holder: Creator(
          name: 'trader${_random.nextInt(100)}',
          display: _mockName(_random.nextInt(10) + 1),
          verified: _random.nextBool(),
          avatar: 'https://i.pravatar.cc/150?img=${_random.nextInt(50)}',
          ionConnect: 'trader-${_random.nextInt(100)}',
        ),
        addresses: Addresses(
          blockchain: '0x${_random.nextInt(0xFFFFFFFF).toRadixString(16)}',
          ionConnect: 'trader-${_random.nextInt(100)}',
        ),
        createdAt: now.toIso8601String(),
        type: side,
        amount: 100.0 + _random.nextDouble() * 1000.0,
        amountUSD: 5.0 + _random.nextDouble() * 500.0,
        balance: 200.0 + _random.nextDouble() * 2000.0,
        balanceUSD: 10.0 + _random.nextDouble() * 1000.0,
      ),
    );
  }

  String _mockName(int id) {
    const names = [
      'Stephan Chan',
      'Jane Doe',
      'Alex Smith',
      'Samuel Bright',
      'Lisa Carter',
      'John Wayne',
      'Maria Stevens',
      'Chris Hall',
      'Kelly Brooks',
      'Oliver Stone',
    ];
    return names[(id - 1) % names.length];
  }
}
