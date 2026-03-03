// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion_swap_client/utils/crypto_amount_converter.dart';

void main() {
  group(
    'toBlockchainUnits',
    () {
      test(
        'returns 0 for empty amount',
        () {
          expect(
            toBlockchainUnits('', 18),
            '0',
          );
        },
      );

      test(
        'converts whole number correctly',
        () {
          expect(
            toBlockchainUnits('1', 18),
            // 1 * 10^18
            '1000000000000000000',
          );
        },
      );

      test(
        'converts decimal number correctly with 18 decimals',
        () {
          expect(
            toBlockchainUnits('1.23', 18),
            '1230000000000000000',
          );
        },
      );

      test(
        'converts decimal number correctly with 6 decimals',
        () {
          expect(
            toBlockchainUnits('1.23', 6),
            '1230000',
          );
        },
      );

      test(
        'converts very small decimal correctly',
        () {
          expect(
            toBlockchainUnits('0.000005', 6),
            '5',
          );
        },
      );
    },
  );
}
