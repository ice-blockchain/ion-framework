// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/utils/crypto.dart';

import '../test_utils.dart';

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
          final result = fromBlockchainUnits(t.input, decimals: t.decimals);
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
          final result = fromBlockchainUnits(t.input, decimals: t.decimals);
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
          final result = fromBlockchainUnits(t.input, decimals: t.decimals);
          expect(result, t.expected);
        });
      });

      parameterizedGroup('0 decimals (integer tokens)', [
        (input: '1', decimals: 0, expected: 1.0),
        (input: '42', decimals: 0, expected: 42.0),
        (input: '1000', decimals: 0, expected: 1000.0),
      ], (t) {
        test('fromBlockchainUnits("${t.input}", ${t.decimals}) returns ${t.expected}', () {
          final result = fromBlockchainUnits(t.input, decimals: t.decimals);
          expect(result, t.expected);
        });
      });
    });

    group('zero values', () {
      test('zero with 18 decimals returns 0.0', () {
        final result = fromBlockchainUnits('0');
        expect(result, 0.0);
      });

      test('zero with 8 decimals returns 0.0', () {
        final result = fromBlockchainUnits('0', decimals: 8);
        expect(result, 0.0);
      });

      test('zero with 0 decimals returns 0.0', () {
        final result = fromBlockchainUnits('0', decimals: 0);
        expect(result, 0.0);
      });
    });

    group('large numbers', () {
      test('handles very large blockchain amounts', () {
        final result = fromBlockchainUnits('999999999999999999999999999999');
        // expect(result, closeTo(999999999999.999999999999999999, 1000));
        expect(result, 999999999999.999999999999999999);
      });

      test('handles maximum safe integer-like values', () {
        final result = fromBlockchainUnits('9007199254740991000000000000000000');
        // expect(result, closeTo(9007199254740991.0, 1000));
        expect(result, 9007199254740991.0);
      });
    });

    group('edge cases', () {
      test('handles very small amounts (1 unit)', () {
        final result = fromBlockchainUnits('1');
        expect(result, 0.000000000000000001);
      });

      test('handles very small amounts (1 unit) with 8 decimals', () {
        final result = fromBlockchainUnits('1', decimals: 8);
        expect(result, 0.00000001);
      });
    });

    group('invalid input handling', () {
      test('returns 0.0 for invalid number string', () {
        final result = fromBlockchainUnits('invalid');
        expect(result, 0.0);
      });

      test('returns 0.0 for empty string', () {
        final result = fromBlockchainUnits('');
        expect(result, 0.0);
      });

      test('returns 0.0 for non-numeric string', () {
        final result = fromBlockchainUnits('abc123');
        expect(result, 0.0);
      });

      test('returns 0.0 for decimal input string', () {
        final result = fromBlockchainUnits('1.5');
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
        final converted = fromBlockchainUnits(blockchainUnits.toString(), decimals: t.decimals);
        expect(converted, t.value);
      });
    });

    test('round-trip conversion works with BigInt input from fromBlockchainUnits', () {
      const inputString = '1000000000000000000';
      const decimals = 18;

      final doubleValue = fromBlockchainUnits(inputString);
      final backToBigInt = toBlockchainUnits(doubleValue, decimals);

      expect(backToBigInt.toString(), inputString);
    });
  });

  group('formatCryptoFull', () {
    group('zero values', () {
      test('formats zero as 0.00', () {
        expect(formatCryptoFull(0), '0.00');
      });
    });

    group('values >= 1M (abbreviated format)', () {
      parameterizedGroup('million values formatting', [
        (value: 1000000.0, expected: '1M'),
        (value: 1500000.0, expected: '1.5M'),
        (value: 1500900.0, expected: '1.5M'), // truncated, not rounded
        (value: 1999999.0, expected: '1.999M'),
        (value: 1999900.0, expected: '1.999M'),
        (value: 12345678.0, expected: '12.345M'),
        (value: 12345678.999, expected: '12.345M'),
        (value: 999999999.0, expected: '999.999M'),
        (value: 1000000.123456, expected: '1M'), // trailing zeros removed
        (value: 2500000.0, expected: '2.5M'),
        (value: 2560000.0, expected: '2.56M'),
        (value: 2567000.0, expected: '2.567M'),
        (value: 2567890.0, expected: '2.567M'), // truncated to 3 decimals
      ], (t) {
        test('formatCryptoFull(${t.value}) returns ${t.expected}', () {
          expect(formatCryptoFull(t.value), t.expected);
        });
      });

      parameterizedGroup('billion values formatting', [
        (value: 1000000000.0, expected: '1B'),
        (value: 1500000000.0, expected: '1.5B'),
        (value: 1234567890.0, expected: '1.234B'),
        (value: 1234567890.999, expected: '1.234B'),
        (value: 999999999999.0, expected: '999.999B'),
        (value: 18308397101.0, expected: '18.308B'),
        (value: 18308397101.537, expected: '18.308B'),
      ], (t) {
        test('formatCryptoFull(${t.value}) returns ${t.expected}', () {
          expect(formatCryptoFull(t.value), t.expected);
        });
      });

      parameterizedGroup('trillion values formatting', [
        (value: 1000000000000.0, expected: '1T'),
        (value: 1500000000000.0, expected: '1.5T'),
        (value: 18308397101537.0, expected: '18.308T'),
        (value: 18308397101537.31, expected: '18.308T'),
        (value: 1234567890123456.0, expected: '1234.567T'),
        (value: 9999999999999999.0, expected: '10000T'),
      ], (t) {
        test('formatCryptoFull(${t.value}) returns ${t.expected}', () {
          expect(formatCryptoFull(t.value), t.expected);
        });
      });

      test('boundary values near 1M', () {
        expect(formatCryptoFull(999999), '999,999.00'); // stays unabbreviated
        expect(formatCryptoFull(1000000), '1M'); // becomes abbreviated
      });
    });

    group('values >= 10 and < 1M (maximum 2 decimal places, minimum 2)', () {
      parameterizedGroup('large values formatting', [
        (value: 11.0, expected: '11.00'),
        (value: 100.0, expected: '100.00'),
        (value: 100.5, expected: '100.50'),
        (value: 100.55, expected: '100.55'),
        (value: 1000.0, expected: '1,000.00'),
        (value: 1000.12, expected: '1,000.12'),
        (value: 1000.123, expected: '1,000.12'),
        (value: 999999.89, expected: '999,999.89'),
        (value: 999999.999, expected: '999,999.99'),
        (value: 50.0, expected: '50.00'),
        (value: 99.99, expected: '99.99'),
        (value: 10.1, expected: '10.10'),
        (value: 999.999, expected: '999.99'),
      ], (t) {
        test('formatCryptoFull(${t.value}) returns ${t.expected}', () {
          expect(formatCryptoFull(t.value), t.expected);
        });
      });
    });

    group('values >= 1 and < 10 (maximum 6 decimal places)', () {
      parameterizedGroup('medium values formatting', [
        (value: 1.0, expected: '1.00'),
        (value: 1.5, expected: '1.50'),
        (value: 1.12, expected: '1.12'),
        (value: 1.123456, expected: '1.123456'),
        (value: 1.1234567, expected: '1.123456'),
        (value: 9.0, expected: '9.00'),
        (value: 9.99, expected: '9.99'),
        (value: 9.999999, expected: '9.999999'),
        (value: 5.123, expected: '5.123'),
        (value: 2.000001, expected: '2.000001'),
        (value: 2.0000001, expected: '2.00'),
        (value: 3.1415926, expected: '3.141592'),
      ], (t) {
        test('formatCryptoFull(${t.value}) returns ${t.expected}', () {
          expect(formatCryptoFull(t.value), t.expected);
        });
      });
    });

    group('values < 1 (maximum 6 decimal places)', () {
      parameterizedGroup('small values formatting', [
        (value: 0.1, expected: '0.10'),
        (value: 0.12, expected: '0.12'),
        (value: 0.123, expected: '0.123'),
        (value: 0.1234, expected: '0.1234'),
        (value: 0.12345, expected: '0.12345'),
        (value: 0.123456, expected: '0.123456'),
        (value: 0.1234567, expected: '0.123456'),
        (value: 0.001, expected: '0.001'),
        (value: 0.0001, expected: '0.0001'),
        (value: 0.00001, expected: '0.00001'),
        (value: 0.000001, expected: '0.000001'),
        (value: 0.0000001, expected: '0.000001'),
        (value: 0.999999, expected: '0.999999'),
        (value: 0.5, expected: '0.50'),
      ], (t) {
        test('formatCryptoFull(${t.value}) returns ${t.expected}', () {
          expect(formatCryptoFull(t.value), t.expected);
        });
      });
    });

    group('with currency symbol', () {
      parameterizedGroup('currency formatting', [
        (value: 0.0, currency: 'BTC', expected: '0.00 BTC'),
        (value: 1.5, currency: 'ETH', expected: '1.50 ETH'),
        (value: 1000.12, currency: 'USD', expected: '1,000.12 USD'),
        (value: 0.00001, currency: 'SATS', expected: '0.00001 SATS'),
        (value: 0.0000119, currency: 'SATS', expected: '0.000011 SATS'),
        (value: 11.0, currency: 'DOGE', expected: '11.00 DOGE'),
        (value: 11.099999999, currency: 'DOGE', expected: '11.09 DOGE'),
        (value: 0.123456, currency: 'ADA', expected: '0.123456 ADA'),
        // Abbreviated format with currency
        (value: 1000000.0, currency: 'USD', expected: '1M USD'),
        (value: 1500000.0, currency: 'BTC', expected: '1.5M BTC'),
        (value: 1000000000.0, currency: 'ETH', expected: '1B ETH'),
        (value: 18308397101537.31, currency: 'USD', expected: '18.308T USD'),
        (value: 2567890.0, currency: 'SATS', expected: '2.567M SATS'),
      ], (t) {
        test('formatCryptoFull(${t.value}, ${t.currency}) returns ${t.expected}', () {
          expect(formatCryptoFull(t.value, t.currency), t.expected);
        });
      });

      test('null currency returns value without suffix', () {
        expect(formatCryptoFull(1.5), '1.50');
      });
    });

    group('boundary values', () {
      test('handles values exactly at boundaries', () {
        expect(formatCryptoFull(1), '1.00');
        expect(formatCryptoFull(10), '10.00');
        expect(formatCryptoFull(0.999999), '0.999999');
        expect(formatCryptoFull(0.9999999), '0.999999');
        expect(formatCryptoFull(10.000001), '10.00');
      });
    });

    group('negative values and zero', () {
      parameterizedGroup('negative values and zero formatting', [
        (value: 0.0, expected: '0.00'),
        (value: -1.0, expected: '0.00'),
        (value: -0.5, expected: '0.00'),
        (value: -1000.0, expected: '0.00'),
        (value: -0.0001, expected: '0.00'),
        (value: -1000000.0, expected: '0.00'),
        (value: -0.000001, expected: '0.00'),
      ], (t) {
        test('formatCryptoFull(${t.value}) returns ${t.expected}', () {
          expect(formatCryptoFull(t.value), t.expected);
        });
      });
    });

    group('edge cases', () {
      test('handles very small numbers correctly', () {
        expect(formatCryptoFull(1e-7), '0.000001');
        expect(formatCryptoFull(1e-6), '0.000001');
        expect(formatCryptoFull(1.23e-6), '0.000001');
      });

      test('handles very small numbers normalized to minimum threshold', () {
        expect(formatCryptoFull(0.00000001), '0.000001');
        expect(formatCryptoFull(0.00000012), '0.000001');
        expect(formatCryptoFull(0.00000123), '0.000001');
        expect(formatCryptoFull(0.000000456), '0.000001');
        expect(formatCryptoFull(0.0000000789), '0.000001');
      });
    });
  });
}
