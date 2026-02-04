// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/utils/date.dart';

void main() {
  group('areSameTimeSlot', () {
    test('24h: same calendar day -> same slot', () {
      final t1 = DateTime(2026, 2, 4, 3, 12);
      final t2 = DateTime(2026, 2, 4, 23, 59);

      expect(areSameTimeSlot(t1, t2, '24h'), true);
    });

    test('24h: different days -> different slots', () {
      final t1 = DateTime(2026, 2, 4, 23, 59);
      final t2 = DateTime(2026, 2, 5, 0, 1);

      expect(areSameTimeSlot(t1, t2, '24h'), false);
    });

    test('1h: same hour -> same slot', () {
      final t1 = DateTime(2026, 2, 4, 16, 1);
      final t2 = DateTime(2026, 2, 4, 16, 59);

      expect(areSameTimeSlot(t1, t2, '1h'), true);
    });

    test('1h: different hours -> different slots', () {
      final t1 = DateTime(2026, 2, 4, 16, 59);
      final t2 = DateTime(2026, 2, 4, 17, 0);

      expect(areSameTimeSlot(t1, t2, '1h'), false);
    });

    test('15m: same 15-minute slot -> same slot', () {
      final t1 = DateTime(2026, 2, 4, 16, 2);
      final t2 = DateTime(2026, 2, 4, 16, 14);

      expect(areSameTimeSlot(t1, t2, '15m'), true);
    });

    test('15m: boundary crossing -> different slots', () {
      final t1 = DateTime(2026, 2, 4, 16, 14);
      final t2 = DateTime(2026, 2, 4, 16, 15);

      expect(areSameTimeSlot(t1, t2, '15m'), false);
    });

    test('5m: same 5-minute slot -> same slot', () {
      final t1 = DateTime(2026, 2, 4, 16, 21);
      final t2 = DateTime(2026, 2, 4, 16, 24);

      expect(areSameTimeSlot(t1, t2, '5m'), true);
    });

    test('5m: different 5-minute slots -> different slots', () {
      final t1 = DateTime(2026, 2, 4, 16, 24);
      final t2 = DateTime(2026, 2, 4, 16, 25);

      expect(areSameTimeSlot(t1, t2, '5m'), false);
    });
  });
}
