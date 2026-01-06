// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/tokenized_communities/utils/formatters.dart';

void main() {
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
