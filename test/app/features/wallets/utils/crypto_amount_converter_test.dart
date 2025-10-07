// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/wallets/utils/crypto_amount_converter.dart';

import '../../../../test_utils.dart';

void main() {
  group('fromBlockchainUnits', () {
    group('standard conversions', () {
      parameterizedGroup('18 decimals (ETH-like)', [
        (input: '1000000000000000000', decimals: 18, expected: 1.0),
        (input: '500000000000000000', decimals: 18, expected: 0.5),
        (input: '1500000000000000000', decimals: 18, expected: 1.5),
        (input: '123456789012345678', decimals: 18, expected: 0.123456789012345678),
      ], (t) {
        test('fromBlockchainUnits("${t.input}", ${t.decimals}) returns ${t.expected}', () {
          final result = fromBlockchainUnits(t.input, t.decimals);
          expect(result, t.expected);
        });
      });

      parameterizedGroup('8 decimals (BTC-like)', [
        (input: '100000000', decimals: 8, expected: 1.0),
        (input: '50000000', decimals: 8, expected: 0.5),
        (input: '150000000', decimals: 8, expected: 1.5),
        (input: '12345678', decimals: 8, expected: 0.12345678),
        (input: '123456789', decimals: 8, expected: 1.23456789),
      ], (t) {
        test('fromBlockchainUnits("${t.input}", ${t.decimals}) returns ${t.expected}', () {
          final result = fromBlockchainUnits(t.input, t.decimals);
          expect(result, t.expected);
        });
      });

      parameterizedGroup('6 decimals (USDC-like)', [
        (input: '1000000', decimals: 6, expected: 1.0),
        (input: '500000', decimals: 6, expected: 0.5),
        (input: '1500000', decimals: 6, expected: 1.5),
        (input: '123456', decimals: 6, expected: 0.123456),
        (input: '1234567', decimals: 6, expected: 1.234567),
      ], (t) {
        test('fromBlockchainUnits("${t.input}", ${t.decimals}) returns ${t.expected}', () {
          final result = fromBlockchainUnits(t.input, t.decimals);
          expect(result, t.expected);
        });
      });

      parameterizedGroup('0 decimals (integer tokens)', [
        (input: '1', decimals: 0, expected: 1.0),
        (input: '42', decimals: 0, expected: 42.0),
        (input: '1000', decimals: 0, expected: 1000.0),
      ], (t) {
        test('fromBlockchainUnits("${t.input}", ${t.decimals}) returns ${t.expected}', () {
          final result = fromBlockchainUnits(t.input, t.decimals);
          expect(result, t.expected);
        });
      });
    });

    group('zero values', () {
      test('zero with 18 decimals returns 0.0', () {
        final result = fromBlockchainUnits('0', 18);
        expect(result, 0.0);
      });

      test('zero with 8 decimals returns 0.0', () {
        final result = fromBlockchainUnits('0', 8);
        expect(result, 0.0);
      });

      test('zero with 0 decimals returns 0.0', () {
        final result = fromBlockchainUnits('0', 0);
        expect(result, 0.0);
      });
    });

    group('large numbers', () {
      test('handles very large blockchain amounts', () {
        final result = fromBlockchainUnits('999999999999999999999999999999', 18);
        // expect(result, closeTo(999999999999.999999999999999999, 1000));
        expect(result, 999999999999.999999999999999999);
      });

      test('handles maximum safe integer-like values', () {
        final result = fromBlockchainUnits('9007199254740991000000000000000000', 18);
        // expect(result, closeTo(9007199254740991.0, 1000));
        expect(result, 9007199254740991.0);
      });
    });

    group('edge cases', () {
      test('handles very small amounts (1 unit)', () {
        final result = fromBlockchainUnits('1', 18);
        expect(result, 0.000000000000000001);
      });

      test('handles very small amounts (1 unit) with 8 decimals', () {
        final result = fromBlockchainUnits('1', 8);
        expect(result, 0.00000001);
      });
    });

    group('invalid input handling', () {
      test('returns 0.0 for invalid number string', () {
        final result = fromBlockchainUnits('invalid', 18);
        expect(result, 0.0);
      });

      test('returns 0.0 for empty string', () {
        final result = fromBlockchainUnits('', 18);
        expect(result, 0.0);
      });

      test('returns 0.0 for non-numeric string', () {
        final result = fromBlockchainUnits('abc123', 18);
        expect(result, 0.0);
      });

      test('returns 0.0 for decimal input string', () {
        final result = fromBlockchainUnits('1.5', 18);
        expect(result, 0.0);
      });
    });
  });

  group('toBlockchainUnits', () {
    group('standard conversions', () {
      parameterizedGroup('18 decimals (ETH-like)', [
        (input: 1.0, decimals: 18, expected: '1000000000000000000'),
        (input: 0.5, decimals: 18, expected: '500000000000000000'),
        (input: 1.5, decimals: 18, expected: '1500000000000000000'),
      ], (t) {
        test('toBlockchainUnits(${t.input}, ${t.decimals}) returns ${t.expected}', () {
          final result = toBlockchainUnits(t.input, t.decimals);
          expect(result.toString(), t.expected);
        });
      });

      parameterizedGroup('8 decimals (BTC-like)', [
        (input: 1.0, decimals: 8, expected: '100000000'),
        (input: 0.5, decimals: 8, expected: '50000000'),
        (input: 1.5, decimals: 8, expected: '150000000'),
        (input: 0.12345678, decimals: 8, expected: '12345678'),
        (input: 1.23456789, decimals: 8, expected: '123456789'),
      ], (t) {
        test('toBlockchainUnits(${t.input}, ${t.decimals}) returns ${t.expected}', () {
          final result = toBlockchainUnits(t.input, t.decimals);
          expect(result.toString(), t.expected);
        });
      });

      parameterizedGroup('6 decimals (USDC-like)', [
        (input: 1.0, decimals: 6, expected: '1000000'),
        (input: 0.5, decimals: 6, expected: '500000'),
        (input: 1.5, decimals: 6, expected: '1500000'),
        (input: 0.123456, decimals: 6, expected: '123456'),
        (input: 1.234567, decimals: 6, expected: '1234567'),
      ], (t) {
        test('toBlockchainUnits(${t.input}, ${t.decimals}) returns ${t.expected}', () {
          final result = toBlockchainUnits(t.input, t.decimals);
          expect(result.toString(), t.expected);
        });
      });

      parameterizedGroup('0 decimals (integer tokens)', [
        (input: 1.0, decimals: 0, expected: '1'),
        (input: 42.0, decimals: 0, expected: '42'),
        (input: 1000.0, decimals: 0, expected: '1000'),
      ], (t) {
        test('toBlockchainUnits(${t.input}, ${t.decimals}) returns ${t.expected}', () {
          final result = toBlockchainUnits(t.input, t.decimals);
          expect(result.toString(), t.expected);
        });
      });
    });

    group('zero values', () {
      test('zero with 18 decimals returns BigInt.zero', () {
        final result = toBlockchainUnits(0, 18);
        expect(result, BigInt.zero);
      });

      test('zero with 0 decimals returns BigInt.zero', () {
        final result = toBlockchainUnits(0, 0);
        expect(result, BigInt.zero);
      });

      test('null value returns BigInt.zero', () {
        final result = toBlockchainUnits(null, 18);
        expect(result, BigInt.zero);
      });
    });

    group('large decimal numbers', () {
      test('handles large decimal amounts', () {
        final result = toBlockchainUnits(1000000000000, 18);
        expect(result.toString(), '1000000000000000000000000000000');
      });

      test('handles very large whole numbers', () {
        final result = toBlockchainUnits(1000000000000, 18);
        expect(result.toString(), '1000000000000000000000000000000');
      });
    });

    group('edge cases', () {
      test('handles very small decimal amounts (1 unit)', () {
        final result = toBlockchainUnits(0.000000000000000001, 18);
        expect(result.toString(), '1');
      });

      test('handles very small amounts (1 unit) with 8 decimals', () {
        final result = toBlockchainUnits(0.00000001, 8);
        expect(result.toString(), '1');
      });
    });
  });

  group('round-trip conversions', () {
    parameterizedGroup('round-trip precision tests', [
      (value: 1.0, decimals: 18),
      (value: 0.5, decimals: 18),
      (value: 1.0, decimals: 8),
      (value: 0.12345678, decimals: 8),
      (value: 0.00000001, decimals: 8),
      (value: 1.0, decimals: 6),
      (value: 0.123456, decimals: 6),
      (value: 0.000001, decimals: 6),
      (value: 42.0, decimals: 0),
    ], (t) {
      test('round-trip conversion preserves precision for ${t.value} with ${t.decimals} decimals',
          () {
        final blockchainUnits = toBlockchainUnits(t.value, t.decimals);
        final converted = fromBlockchainUnits(blockchainUnits.toString(), t.decimals);
        expect(converted, t.value);
      });
    });

    test('round-trip conversion works with BigInt input from fromBlockchainUnits', () {
      const inputString = '1000000000000000000';
      const decimals = 18;

      final doubleValue = fromBlockchainUnits(inputString, decimals);
      final backToBigInt = toBlockchainUnits(doubleValue, decimals);

      expect(backToBigInt.toString(), inputString);
    });
  });
}
