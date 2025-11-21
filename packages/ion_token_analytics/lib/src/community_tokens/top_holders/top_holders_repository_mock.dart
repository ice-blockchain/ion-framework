// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:math';

import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:ion_token_analytics/src/community_tokens/top_holders/top_holders_repository.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

/// MOCK REPOSITORY: Streams a list of TopHolders with periodic updates.
class TopHoldersRepositoryMock implements TopHoldersRepository {
  final _random = Random();

  @override
  Future<NetworkSubscription<List<TopHolder>>> subscribeToTopHolders(
    String ionConnectAddress,
  ) async {
    // A StreamController that emits TopHolder lists.
    final controller = StreamController<List<TopHolder>>();

    // Initial mock data (10 holders)
    var holders = _generateInitialMockHolders();

    // Emit the initial list immediately.
    controller.add(holders);

    // Emit random updates every 2-3 seconds.
    Timer.periodic(Duration(seconds: 2 + Random().nextInt(2)), (timer) {
      holders = _applyRandomUpdate(holders);
      controller.add(List.unmodifiable(holders));
    });

    return NetworkSubscription<List<TopHolder>>(
      stream: controller.stream,
      close: () async {
        await controller.close();
      },
    );
  }

  // HELPER: Generate initial 10 mock holders
  List<TopHolder> _generateInitialMockHolders() {
    return List.generate(10, (index) {
      final rank = index + 1;
      return TopHolder(
        creator: Creator(
          name: 'creator$rank',
          display: 'Creator $rank',
          // ignore: use_is_even_rather_than_modulo
          verified: rank % 2 == 0,
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
          addresses: Addresses(blockchain: '0x1234567890abcdef$rank', ionConnect: 'address-$rank'),
        ),
      );
    });
  }

  // HELPER: Apply a random update to simulate live changes
  List<TopHolder> _applyRandomUpdate(List<TopHolder> list) {
    final newList = List<TopHolder>.from(list);
    final index = _random.nextInt(newList.length);

    final item = newList[index];

    // Randomly update amount, supply share, rank, etc.
    final updated = item.copyWith(
      position: item.position.copyWith(
        amount: item.position.amount * (0.98 + _random.nextDouble() * 0.05),
        amountUSD: item.position.amountUSD * (0.98 + _random.nextDouble() * 0.05),
        supplyShare: item.position.supplyShare * (0.98 + _random.nextDouble() * 0.04),
      ),
    );

    newList[index] = updated;

    return newList;
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
