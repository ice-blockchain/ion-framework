import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/tokenized_communities/utils/formatters.dart';

void main() {
  group('formatPriceWithSubscript', () {
    test('standard values', () {
      expect(formatPriceWithSubscript(1.23), r'$1.23');
      expect(formatPriceWithSubscript(0.1), r'$0.10');
      expect(formatPriceWithSubscript(0.01), r'$0.01');
      expect(formatPriceWithSubscript(0.001), r'$0.001');
    });

    test('rounding for values >= 0.1', () {
      expect(formatPriceWithSubscript(0.123), r'$0.12');
      expect(formatPriceWithSubscript(0.1234), r'$0.12');
      expect(formatPriceWithSubscript(0.101), r'$0.10');
      expect(formatPriceWithSubscript(0.1001), r'$0.10');
    });

    test('zero value', () {
      expect(formatPriceWithSubscript(0), r'$0.00');
    });

    test('subscript notation', () {
      expect(formatPriceWithSubscript(0.0001), r'$0.0₃1');
      expect(formatPriceWithSubscript(0.00001), r'$0.0₄1');
      expect(formatPriceWithSubscript(0.000001), r'$0.0₅1');
    });

    test('negative values', () {
      expect(formatPriceWithSubscript(-0.0001), r'-$0.0₃1');
    });
  });
}
