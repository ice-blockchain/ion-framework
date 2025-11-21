// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/communities/utils/price_label_formatter.dart';

import '../../../../test_utils.dart';

void main() {
  parameterizedGroup('PriceLabelFormatter.format', [
    // abs >= 0.1 -> fullText with 4 decimals
    (value: 0.1, fullText: '0.1000', prefix: null, sub: null, trail: null),
    (value: 1.234567, fullText: '1.2346', prefix: null, sub: null, trail: null),
    (value: -0.1, fullText: '-0.1000', prefix: null, sub: null, trail: null),

    // zero -> '0.0000'
    (value: 0.0, fullText: '0.0000', prefix: null, sub: null, trail: null),

    // small positive numbers: prefix '0.0', subscript only when zeros > 2
    // 0.03 -> exponent -2 => zeros = 1 -> no subscript
    (value: 0.03, fullText: null, prefix: '0.0', sub: null, trail: '30'),
    // 0.003 -> exponent -3 => zeros = 2 -> no subscript (changed rule)
    (value: 0.003, fullText: null, prefix: '0.0', sub: null, trail: '30'),
    // 0.0003 -> exponent -4 => zeros = 3 -> subscript '3'
    (value: 0.0003, fullText: null, prefix: '0.0', sub: '3', trail: '30'),
    // 0.000033 -> exponent -5 => zeros = 4 -> subscript '4'
    (value: 0.000033, fullText: null, prefix: '0.0', sub: '4', trail: '33'),

    // small negative numbers: sign kept in prefix
    (value: -0.03, fullText: null, prefix: '-0.0', sub: null, trail: '30'),
    (value: -0.003, fullText: null, prefix: '-0.0', sub: null, trail: '30'),
    (value: -0.0003, fullText: null, prefix: '-0.0', sub: '3', trail: '30'),
  ], (t) {
    test('format(${t.value})', () {
      final parts = PriceLabelFormatter.format(t.value);
      expect(parts.fullText, t.fullText);
      expect(parts.prefix, t.prefix);
      expect(parts.subscript, t.sub);
      expect(parts.trailing, t.trail);
    });
  });
}
