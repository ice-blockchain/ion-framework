// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/utils/calculate_price_impact.dart';

void main() {
  group('calculatePriceImpact', () {
    test('returns negative impact when buy value is less than sell value', () {
      final result = calculatePriceImpact(
        sellAmount: 1,
        buyAmount: 1950,
        sellPriceUsd: 2000,
        buyPriceUsd: 1,
      );

      expect(result, closeTo(-2.5, 0.01));
    });

    test('returns zero impact when prices perfectly match', () {
      final result = calculatePriceImpact(
        sellAmount: 1,
        buyAmount: 2000,
        sellPriceUsd: 2000,
        buyPriceUsd: 1,
      );

      expect(result, closeTo(0, 0.001));
    });

    test('returns positive impact when buy value exceeds sell value', () {
      final result = calculatePriceImpact(
        sellAmount: 1,
        buyAmount: 2100,
        sellPriceUsd: 2000,
        buyPriceUsd: 1,
      );

      expect(result, closeTo(5, 0.01));
    });

    test('returns high negative impact for large price discrepancy', () {
      final result = calculatePriceImpact(
        sellAmount: 1,
        buyAmount: 1800,
        sellPriceUsd: 2000,
        buyPriceUsd: 1,
      );

      expect(result, closeTo(-10, 0.01));
    });

    test('returns null when sellAmount is zero', () {
      final result = calculatePriceImpact(
        sellAmount: 0,
        buyAmount: 1950,
        sellPriceUsd: 2000,
        buyPriceUsd: 1,
      );

      expect(result, isNull);
    });

    test('returns null when buyAmount is zero', () {
      final result = calculatePriceImpact(
        sellAmount: 1,
        buyAmount: 0,
        sellPriceUsd: 2000,
        buyPriceUsd: 1,
      );

      expect(result, isNull);
    });

    test('returns null when buyPriceUsd is zero', () {
      final result = calculatePriceImpact(
        sellAmount: 1,
        buyAmount: 1950,
        sellPriceUsd: 2000,
        buyPriceUsd: 0,
      );

      expect(result, isNull);
    });
  });
}
