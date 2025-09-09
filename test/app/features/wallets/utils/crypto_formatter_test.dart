// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/wallets/views/utils/crypto_formatter.dart';

import '../../../../test_utils.dart';

void main() {
  group('formatCrypto', () {
    group('zero values', () {
      test('formats zero as 0.00', () {
        expect(formatCrypto(0), '0.00');
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
        test('formatCrypto(${t.value}) returns ${t.expected}', () {
          expect(formatCrypto(t.value), t.expected);
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
        test('formatCrypto(${t.value}) returns ${t.expected}', () {
          expect(formatCrypto(t.value), t.expected);
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
        test('formatCrypto(${t.value}) returns ${t.expected}', () {
          expect(formatCrypto(t.value), t.expected);
        });
      });

      test('boundary values near 1M', () {
        expect(formatCrypto(999999), '999,999.00'); // stays unabbreviated
        expect(formatCrypto(1000000), '1M'); // becomes abbreviated
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
        test('formatCrypto(${t.value}) returns ${t.expected}', () {
          expect(formatCrypto(t.value), t.expected);
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
        test('formatCrypto(${t.value}) returns ${t.expected}', () {
          expect(formatCrypto(t.value), t.expected);
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
        (value: 0.0000001, expected: '0.0(6)1'),
        (value: 0.999999, expected: '0.999999'),
        (value: 0.5, expected: '0.50'),
      ], (t) {
        test('formatCrypto(${t.value}) returns ${t.expected}', () {
          expect(formatCrypto(t.value), t.expected);
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
        test('formatCrypto(${t.value}, ${t.currency}) returns ${t.expected}', () {
          expect(formatCrypto(t.value, t.currency), t.expected);
        });
      });

      test('null currency returns value without suffix', () {
        expect(formatCrypto(1.5), '1.50');
      });
    });

    group('boundary values', () {
      test('handles values exactly at boundaries', () {
        expect(formatCrypto(1), '1.00');
        expect(formatCrypto(10), '10.00');
        expect(formatCrypto(0.999999), '0.999999');
        expect(formatCrypto(0.9999999), '0.999999');
        expect(formatCrypto(10.000001), '10.00');
      });
    });

    group('edge cases', () {
      test('handles very small numbers correctly', () {
        expect(formatCrypto(1e-7), '0.0(6)1');
        expect(formatCrypto(1e-6), '0.000001');
        expect(formatCrypto(1.23e-6), '0.000001');
      });

      test('handles very small numbers with scientific notation format', () {
        expect(formatCrypto(0.00000001), '0.0(7)1');
        expect(formatCrypto(0.00000012), '0.0(6)1');
        expect(formatCrypto(0.00000123), '0.000001');
        expect(formatCrypto(0.000000456), '0.0(6)4');
        expect(formatCrypto(0.0000000789), '0.0(7)7');
      });
    });
  });
}
