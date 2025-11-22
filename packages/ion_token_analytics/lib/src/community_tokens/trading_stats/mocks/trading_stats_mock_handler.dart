// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:math';

import 'package:ion_token_analytics/src/community_tokens/trading_stats/models/models.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class TradingStatsMockHandler {
  static final _rnd = Random();

  Future<NetworkSubscription<T>> handleSubscription<T>() async {
    final controller = StreamController<T>();
    Timer? timer;

    // 1) Initial snapshot (like backend)
    var snapshot = _generateSnapshot();
    // Cast to T (which is Map<String, TradingStats>)
    // We need to ensure T matches the expected type or cast safely
    if (!controller.isClosed) {
      controller.add(snapshot as T);
    }

    // 2) Streaming updates every 2 seconds
    timer = Timer.periodic(const Duration(seconds: 2), (_) {
      snapshot = _updateRandom(snapshot);
      if (!controller.isClosed) {
        controller.add(snapshot as T);
      }
    });

    return NetworkSubscription<T>(
      stream: controller.stream,
      close: () async {
        timer?.cancel();
        await controller.close();
      },
    );
  }

  // --- Mock Data Generation Logic ---

  // Helper function to generate random trading stats
  TradingStats _generateStats() {
    // Generate realistic number of trades (10-200)
    final buys = _rnd.nextInt(190) + 10;
    final sells = _rnd.nextInt(190) + 10;

    // Generate realistic USD amounts per transaction (10-100 USD)
    final avgPricePerBuy = 10 + _rnd.nextDouble() * 90;
    final avgPricePerSell = 10 + _rnd.nextDouble() * 90;

    // Sometimes make sells > buys to get negative netBuy (30% chance)
    final shouldBeNegative = _rnd.nextDouble() < 0.3;
    final buysUsd = buys * avgPricePerBuy;
    final sellsUsd = shouldBeNegative
        ? sells *
              (avgPricePerSell * 1.5) // Make sells larger to ensure negative netBuy
        : sells * avgPricePerSell;

    final netBuy = buysUsd - sellsUsd;

    return TradingStats(
      volumeUSD: buysUsd + sellsUsd,
      numberOfBuys: buys,
      numberOfSells: sells,
      buysTotalAmountUSD: buysUsd,
      sellsTotalAmountUSD: sellsUsd,
      netBuy: netBuy,
    );
  }

  // Helper function to generate a random snapshot of trading stats
  Map<String, TradingStats> _generateSnapshot() {
    return {
      '5m': _generateStats(),
      '1h': _generateStats(),
      '6h': _generateStats(),
      '24h': _generateStats(),
    };
  }

  // Helper function to update a random timeframe with new trading stats
  Map<String, TradingStats> _updateRandom(Map<String, TradingStats> current) {
    // Update a single random timeframe, simulating realistic trading updates
    final keys = current.keys.toList();
    final key = keys[_rnd.nextInt(keys.length)];

    final updated = {
      ...current,
      key: _generateStats(), // new stats for that one timeframe
    };

    return updated;
  }

  @override
  Future<NetworkSubscription<Map<String, TradingStats>>> subscribeToTradingStats(
    String ionConnectAddress,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));

    final controller = StreamController<Map<String, TradingStats>>();
    Timer? timer;

    // 1) Initial snapshot (like backend)
    var snapshot = _generateSnapshot();
    controller.add(snapshot);

    // 2) Streaming updates every 2 seconds
    timer = Timer.periodic(const Duration(seconds: 2), (_) {
      snapshot = _updateRandom(snapshot);
      if (!controller.isClosed) {
        controller.add(snapshot);
      }
    });

    return NetworkSubscription(
      stream: controller.stream,
      close: () async {
        timer?.cancel();
        await controller.close();
      },
    );
  }
}
