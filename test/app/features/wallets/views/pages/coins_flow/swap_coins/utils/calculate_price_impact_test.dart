// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/utils/calculate_price_impact.dart';

void main() {
  group('calculatePriceImpact', () {
    test('returns negative impact when buy value is less than sell value', () {
      final result = calculatePriceImpact(
        sellAmount: 1,
        sellPriceUSD: 2000,
        buyPriceUSD: 1,
        exchangeRate: 1950,
      );

      expect(result, closeTo(-2.5, 0.01));
    });

    test('returns zero impact when prices perfectly match', () {
      final result = calculatePriceImpact(
        sellAmount: 1,
        sellPriceUSD: 2000,
        buyPriceUSD: 1,
        exchangeRate: 2000,
      );

      expect(result, closeTo(0, 0.001));
    });

    test('returns positive impact when buy value exceeds sell value', () {
      final result = calculatePriceImpact(
        sellAmount: 1,
        sellPriceUSD: 2000,
        buyPriceUSD: 1,
        exchangeRate: 2100,
      );

      expect(result, closeTo(5, 0.01));
    });

    test('returns high negative impact for large price discrepancy', () {
      final result = calculatePriceImpact(
        sellAmount: 1,
        sellPriceUSD: 2000,
        buyPriceUSD: 1,
        exchangeRate: 1800,
      );

      expect(result, closeTo(-10, 0.01));
    });

    test('returns null when sellAmount is zero', () {
      final result = calculatePriceImpact(
        sellAmount: 0,
        sellPriceUSD: 2000,
        buyPriceUSD: 1,
        exchangeRate: 1950,
      );

      expect(result, isNull);
    });

    test('returns null when sellAmount is negative', () {
      final result = calculatePriceImpact(
        sellAmount: -1,
        sellPriceUSD: 2000,
        buyPriceUSD: 1,
        exchangeRate: 1950,
      );

      expect(result, isNull);
    });

    test('returns null when sellPriceUSD is zero', () {
      final result = calculatePriceImpact(
        sellAmount: 1,
        sellPriceUSD: 0,
        buyPriceUSD: 1,
        exchangeRate: 1950,
      );

      expect(result, isNull);
    });

    test('returns null when sellPriceUSD is negative', () {
      final result = calculatePriceImpact(
        sellAmount: 1,
        sellPriceUSD: -100,
        buyPriceUSD: 1,
        exchangeRate: 1950,
      );

      expect(result, isNull);
    });

    test('returns null when buyPriceUSD is zero', () {
      final result = calculatePriceImpact(
        sellAmount: 1,
        sellPriceUSD: 2000,
        buyPriceUSD: 0,
        exchangeRate: 1950,
      );

      expect(result, isNull);
    });

    test('returns null when buyPriceUSD is negative', () {
      final result = calculatePriceImpact(
        sellAmount: 1,
        sellPriceUSD: 2000,
        buyPriceUSD: -1,
        exchangeRate: 1950,
      );

      expect(result, isNull);
    });

    test('handles very small amounts without floating point issues', () {
      final result = calculatePriceImpact(
        sellAmount: 0.000001,
        sellPriceUSD: 2000,
        buyPriceUSD: 1,
        exchangeRate: 1950,
      );

      expect(result, closeTo(-2.5, 0.01));
    });

    test('handles large amounts correctly', () {
      final result = calculatePriceImpact(
        sellAmount: 1000000,
        sellPriceUSD: 2000,
        buyPriceUSD: 1,
        exchangeRate: 1950,
      );

      expect(result, closeTo(-2.5, 0.01));
    });
  });
}
