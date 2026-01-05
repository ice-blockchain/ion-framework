// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/tokenized_communities/utils/market_data_formatter.dart';

void main() {
  group('formatCompactOrSubscript', () {
    test('zero value', () {
      expect(MarketDataFormatter.formatCompactOrSubscript(0), r'$0');
    });

    test('small values (< 0.01) use subscript notation', () {
      expect(MarketDataFormatter.formatCompactOrSubscript(0.003), r'$0.0₂3');
      expect(MarketDataFormatter.formatCompactOrSubscript(0.0001), r'$0.0₃1');
    });

    test('medium values (0.01 to < 1.0) use price format with decimals', () {
      expect(MarketDataFormatter.formatCompactOrSubscript(0.8911), r'$0.89');
      expect(MarketDataFormatter.formatCompactOrSubscript(0.01), r'$0.01');
      expect(MarketDataFormatter.formatCompactOrSubscript(0.8799), r'$0.88');
      expect(MarketDataFormatter.formatCompactOrSubscript(0.5), r'$0.50');
    });

    test('large values (>= 1.0) use compact notation', () {
      expect(MarketDataFormatter.formatCompactOrSubscript(1234), r'$1.23K');
      expect(MarketDataFormatter.formatCompactOrSubscript(1234567), r'$1.23M');
      expect(MarketDataFormatter.formatCompactOrSubscript(1), r'$1');
      expect(MarketDataFormatter.formatCompactOrSubscript(100), r'$100');
    });

    test('negative values', () {
      expect(MarketDataFormatter.formatCompactOrSubscript(-0.8911), r'-$0.89');
      expect(MarketDataFormatter.formatCompactOrSubscript(-0.003), r'-$0.0₂3');
    });
  });
}
