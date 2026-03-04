// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/wallets/utils/format_approx_usd.dart';

import '../../../../test_utils.dart';

String _approximate(String value) => '≈ $value';

void main() {
  parameterizedGroup('formatApproxUSD above minDisplayUSD', [
    (amount: 0.02, expected: '≈ 0.02'),
    (amount: 1.0, expected: '≈ 1.00'),
    (amount: 0.5, expected: '≈ 0.50'),
    (amount: 1234.56, expected: '≈ 1,234.56'),
  ], (t) {
    test(
      'formatApproxUSD(${t.amount})',
      () {
        final result = formatApproxUSD(t.amount, _approximate);
        expect(result, t.expected);
      },
    );
  });

  parameterizedGroup('formatApproxUSD at or below minDisplayUSD', [
    (amount: 0.01, expected: r'$0.01'),
    (amount: 0.009, expected: r'< $0.01'),
    (amount: 0.001, expected: r'< $0.01'),
    (amount: 0.0001, expected: r'< $0.01'),
    (amount: 0.0, expected: r'$0.00'),
    (amount: -0.005, expected: r'< $0.01'),
    (amount: -1.0, expected: r'-$1.00'),
  ], (t) {
    test(
      'formatApproxUSD(${t.amount})',
      () {
        final result = formatApproxUSD(t.amount, _approximate);
        expect(result, t.expected);
      },
    );
  });
}
