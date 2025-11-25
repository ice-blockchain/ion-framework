// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:math';

import 'package:ion_token_analytics/ion_token_analytics.dart';

class TopHoldersMockHandler {
  final _random = Random();

  Future<NetworkSubscription<T>> handleSubscription<T>(int limit) async {
    // We need a controller that emits raw JSON events (Map<String, dynamic>)
    // because the repository expects Stream<dynamic> which it then transforms.
    final controller = StreamController<T>();

    // Helper to add to controller safely
    void addToController(dynamic event) {
      if (!controller.isClosed) {
        controller.add(event as T);
      }
    }

    // 1. Generate Initial List
    final initialHolders = _generateInitialMockHolders(limit);

    // Feed initial list one-by-one
    for (final holder in initialHolders) {
      addToController(holder.toJson());
    }

    // 2. Send Marker after a short delay
    Future.delayed(const Duration(milliseconds: 200), () {
      addToController(<String, dynamic>{}); // Empty JSON Marker
    });

    // 3. Emit random updates
    final updateTimer = Timer.periodic(Duration(seconds: 2 + _random.nextInt(2)), (timer) {
      final update = _generateRandomUpdate(initialHolders);
      addToController(update.toJson());
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

  List<TopHolder> _generateInitialMockHolders(int count) {
    return List.generate(count, (index) {
      final rank = index + 1;
      return _createMockHolder(rank);
    });
  }

  TopHolder _createMockHolder(int rank) {
    return TopHolder(
      creator: Creator(
        name: 'creator$rank',
        display: 'Creator $rank',
        verified: rank.isEven,
        avatar: 'https://i.pravatar.cc/150?img=${rank + 10}',
        ionConnect: 'creator-$rank',
      ),
      position: TopHolderPosition(
        holder: Creator(
          name: 'holder$rank',
          display: _mockName(rank),
          verified: rank == 1 || rank == 3,
          avatar: 'https://i.pravatar.cc/150?img=$rank',
          ionConnect: 'holder-$rank',
        ),
        type: 'holder',
        rank: rank,
        amount: 10_000_000.0 - rank * 100_000,
        amountUSD: 500.0 + (rank * 12),
        supplyShare: (12 - rank) * 1.17,
        addresses: Addresses(
          blockchain: '0x1234567890abcdef$rank',
          ionConnect: 'new-king-${_random.nextInt(10000)}',
        ),
      ),
    );
  }

  TopHolder _generateRandomUpdate(List<TopHolder> currentPool) {
    if (_random.nextBool()) {
      // Update existing
      final target = currentPool[_random.nextInt(currentPool.length)];
      return target.copyWith(
        position: target.position.copyWith(
          amount: target.position.amount + (_random.nextDouble() * 1000),
        ),
      );
    } else {
      // New Rank 1 (Shift)
      final newHolder = _createMockHolder(1).copyWith(
        position: _createMockHolder(1).position.copyWith(
          holder: Creator(
            name: 'new_king',
            display: 'New King ${_random.nextInt(100)}',
            verified: true,
            avatar: 'https://i.pravatar.cc/150?img=${_random.nextInt(50)}',
            ionConnect: 'new-king-${_random.nextInt(10000)}',
          ),
          rank: 1,
          amount: 20_000_000,
        ),
      );
      return newHolder;
    }
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
