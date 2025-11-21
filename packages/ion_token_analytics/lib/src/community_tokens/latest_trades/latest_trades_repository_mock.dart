// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:math';

import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:ion_token_analytics/src/community_tokens/latest_trades/latest_trades_repository.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

/// MOCK REPOSITORY: Streams a list of LatestTrades with periodic updates.
class LatestTradesRepositoryMock implements LatestTradesRepository {
  final _random = Random();
  Timer? _timer;

  @override
  Future<NetworkSubscription<List<LatestTrade>>> subscribeToLatestTrades(
    String ionConnectAddress,
  ) async {
    final controller = StreamController<List<LatestTrade>>();

    // Initial mock data (10 trades)
    var trades = _generateInitialMockTrades();

    // Emit the initial list immediately.
    if (!controller.isClosed) {
      controller.add(trades);
    }

    // Emit random updates every 2-3 seconds.
    _timer = Timer.periodic(Duration(seconds: 2 + Random().nextInt(2)), (timer) {
      trades = _applyRandomUpdate(trades);
      if (!controller.isClosed) {
        controller.add(List.unmodifiable(trades));
      }
    });

    return NetworkSubscription<List<LatestTrade>>(
      stream: controller.stream,
      close: () async {
        _timer?.cancel();
        await controller.close();
      },
    );
  }

  // HELPER: Generate initial 10 mock trades
  List<LatestTrade> _generateInitialMockTrades() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return List.generate(10, (index) {
      final side = _random.nextBool() ? 'buy' : 'sell';
      final minutesAgo = (index + 1) * 5;
      return LatestTrade(
        trader: Creator(
          name: 'trader${index + 1}',
          display: _mockName(index + 1),
          verified: (index + 1) % 3 == 0,
          avatar: 'https://i.pravatar.cc/150?img=${index + 1}',
          ionConnect: 'trader-${index + 1}',
        ),
        amount: 100.0 + _random.nextDouble() * 1000.0,
        amountUSD: 5.0 + _random.nextDouble() * 500.0,
        timestamp: now - (minutesAgo * 60 * 1000),
        side: side,
        addresses: Addresses(
          blockchain: '0x${_random.nextInt(0xFFFFFFFF).toRadixString(16)}',
          ionConnect: 'trader-${index + 1}',
        ),
      );
    });
  }

  // HELPER: Apply a random update to simulate live changes
  List<LatestTrade> _applyRandomUpdate(List<LatestTrade> list) {
    // Remove oldest trade (first item)
    final newList = List<LatestTrade>.from(list)..removeAt(0);

    // Add a new trade at the end
    final now = DateTime.now().millisecondsSinceEpoch;
    final side = _random.nextBool() ? 'buy' : 'sell';
    final newTrade = LatestTrade(
      trader: Creator(
        name: 'trader${_random.nextInt(100)}',
        display: _mockName(_random.nextInt(10) + 1),
        verified: _random.nextBool(),
        avatar: 'https://i.pravatar.cc/150?img=${_random.nextInt(50)}',
        ionConnect: 'trader-${_random.nextInt(100)}',
      ),
      amount: 100.0 + _random.nextDouble() * 1000.0,
      amountUSD: 5.0 + _random.nextDouble() * 500.0,
      timestamp: now,
      side: side,
      addresses: Addresses(
        blockchain: '0x${_random.nextInt(0xFFFFFFFF).toRadixString(16)}',
        ionConnect: 'trader-${_random.nextInt(100)}',
      ),
    );

    newList.add(newTrade);

    return newList;
  }

  String _mockName(int id) {
    const names = [
      'Mike Jay Evans',
      'Samuel Smith',
      'Saul Bettings',
      'Jane Doe',
      'Alex Smith',
      'Lisa Carter',
      'John Wayne',
      'Maria Stevens',
      'Chris Hall',
      'Kelly Brooks',
    ];
    return names[(id - 1) % names.length];
  }
}
