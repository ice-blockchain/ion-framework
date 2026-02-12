// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/tokenized_communities/utils/formatters.dart';
import 'package:ion/app/utils/formatters.dart';

import '../../../../test_utils.dart';

void main() {
  parameterizedGroup('formatTokenAmountWithSubscript', [
    (value: 0.0, expected: '0.00'),
    (value: 1234.56, expected: '1.23K'),
    (value: 1000000.0, expected: '1.00M'),
    (value: 1.0, expected: '1.00'),
    (value: 999.99, expected: '999.99'),
    (value: 0.1, expected: '0.10'),
    (value: 0.12, expected: '0.12'),
    (value: 0.001, expected: '0.001'),
    (value: 0.0001, expected: '0.0₃1'),
    (value: 0.00001, expected: '0.0₄1'),
    (value: 0.000123, expected: '0.0₃12'),
    (value: 0.00000000005, expected: '0.0₁₀5'),
    (value: -0.00001, expected: '-0.0₄1'),
  ], (t) {
    test(
      'formatTokenAmountWithSubscript(${t.value})',
      () {
        final result = formatTokenAmountWithSubscript(t.value);
        expect(result, t.expected);
      },
    );
  });

  group('formatPercent', () {
    test('zero value', () {
      expect(formatPercent(0), '0.00%'); // Zero has no sign
    });

    test('small values (< 100) show 2 decimals', () {
      expect(formatPercent(29.07), '+29.07%');
      expect(formatPercent(0.55), '+0.55%');
      expect(formatPercent(99.99), '+99.99%');
      expect(formatPercent(99.9877), '+99.99%'); // rounds to 2 decimals
    });

    test('values >= 100 show rounded integers with thousand separators', () {
      expect(formatPercent(100), '+100%');
      expect(formatPercent(101.5), '+102%');
      expect(formatPercent(987.3), '+987%');
      expect(formatPercent(1000), '+1,000%');
      expect(formatPercent(1887), '+1,887%');
      expect(formatPercent(1888999), '+1,888,999%');
    });

    test('negative values', () {
      expect(formatPercent(-29.07), '-29.07%');
      expect(formatPercent(-100), '-100%');
      expect(formatPercent(-1000), '-1,000%');
      expect(formatPercent(-1888999), '-1,888,999%');
    });

    test('boundary values', () {
      expect(formatPercent(99.99), '+99.99%'); // exactly 2 decimals, no rounding
      expect(formatPercent(99.999), '+100.00%'); // rounds up to 100.00 (3rd decimal is 9)
      expect(formatPercent(100), '+100%');
      expect(formatPercent(100.4), '+100%');
      expect(formatPercent(100.5), '+101%');
    });
  });
}
