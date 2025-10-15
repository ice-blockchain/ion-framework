// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/utils/num.dart';

import '../test_utils.dart';

void main() {
  parameterizedGroup('formatCount', [
    (value: 9999, expected: '9,999'),
    (value: 10000, expected: '10K'),
    (value: 10120, expected: '10.1K'),
    (value: 12345, expected: '12.3K'),
    (value: 99999, expected: '100K'),
    (value: 999999, expected: '1M'),
    (value: 1000000, expected: '1M'),
    (value: 1234567, expected: '1.23M'),
    (value: 12345678, expected: '12.3M'),
    (value: 500, expected: '500'),
    (value: 0, expected: '0'),
  ], (t) {
    test(
      'formatCount(${t.value})',
      () {
        final result = formatCount(t.value);
        expect(result, t.expected);
      },
    );
  });
  parameterizedGroup('formatted double value with default params', [
    (value: 1.0, expected: '1.00'),
    (value: 1.01, expected: '1.01'),
    (value: 1.011, expected: '1.01'),
    (value: 1000.1, expected: '1,000.10'),
    (value: 1000000.1, expected: '1,000,000.10'),
    (value: 1000000000.1, expected: '1,000,000,000.10'),
  ], (t) {
    test(
      'formatDouble(${t.value})',
      () {
        final result = formatDouble(t.value);
        expect(result, t.expected);
      },
    );
  });

  parameterizedGroup('formatted double value with specified params', [
    (value: 1.0, expected: '1.000'),
    (value: 1.01, expected: '1.010'),
    (value: 1.011, expected: '1.011'),
    (value: 1000.1, expected: '1,000.100'),
    (value: 1000000.1, expected: '1,000,000.100'),
    (value: 1000000000.1, expected: '1,000,000,000.100'),
    (value: 0.00001, expected: '0.00001'),
  ], (t) {
    test(
      'formatDouble(${t.value})',
      () {
        final result = formatDouble(t.value, maximumFractionDigits: 5, minimumFractionDigits: 3);
        expect(result, t.expected);
      },
    );
  });
}
