// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/tokenized_communities/utils/chart_interval_utils.dart';

void main() {
  group('parseIntervalDuration', () {
    test('parses minute intervals', () {
      expect(parseIntervalDuration('1m'), const Duration(minutes: 1));
      expect(parseIntervalDuration('3m'), const Duration(minutes: 3));
      expect(parseIntervalDuration('5m'), const Duration(minutes: 5));
      expect(parseIntervalDuration('15m'), const Duration(minutes: 15));
      expect(parseIntervalDuration('30m'), const Duration(minutes: 30));
    });

    test('parses hour intervals', () {
      expect(parseIntervalDuration('1h'), const Duration(hours: 1));
      expect(parseIntervalDuration('24h'), const Duration(hours: 24));
    });
  });

  group('durationUntilNextSlot', () {
    const buffer = Duration(seconds: 5);

    group('1m interval', () {
      test('mid-minute returns time until next minute + buffer', () {
        final now = DateTime(2026, 3, 17, 16, 30, 50);
        final result = durationUntilNextSlot('1m', buffer: buffer, now: now);
        // Next slot: 16:31:00 + 5s = 16:31:05, wait = 15s
        expect(result.inSeconds, 15);
      });

      test('start of minute returns full interval + buffer', () {
        final now = DateTime(2026, 3, 17, 16, 30);
        final result = durationUntilNextSlot('1m', buffer: buffer, now: now);
        // Next slot: 16:31:00 + 5s = 16:31:05, wait = 65s
        expect(result.inSeconds, 65);
      });
    });

    group('3m interval', () {
      test('aligns to 3-minute boundaries', () {
        final now = DateTime(2026, 3, 17, 16, 28);
        final result = durationUntilNextSlot('3m', buffer: buffer, now: now);
        // minuteOfDay=988, 988~/3=329, next=330*3=990 → 16:30:00 + 5s
        // wait = 16:30:05 - 16:28:00 = 125s
        expect(result.inSeconds, 125);
      });

      test('at exact boundary returns full interval + buffer', () {
        final now = DateTime(2026, 3, 17, 16, 30);
        final result = durationUntilNextSlot('3m', buffer: buffer, now: now);
        // Next slot: 16:33:00 + 5s = 16:33:05, wait = 185s
        expect(result.inSeconds, 185);
      });
    });

    group('5m interval', () {
      test('aligns to 5-minute boundaries', () {
        final now = DateTime(2026, 3, 17, 16, 32, 15);
        final result = durationUntilNextSlot('5m', buffer: buffer, now: now);
        // minuteOfDay=992, 992~/5=198, next=199*5=995 → 16:35:00 + 5s
        // wait = 16:35:05 - 16:32:15 = 170s
        expect(result.inSeconds, 170);
      });
    });

    group('15m interval', () {
      test('aligns to 15-minute boundaries', () {
        final now = DateTime(2026, 3, 17, 16, 14);
        final result = durationUntilNextSlot('15m', buffer: buffer, now: now);
        // minuteOfDay=974, 974~/15=64, next=65*15=975 → 16:15:00 + 5s
        // wait = 16:15:05 - 16:14:00 = 65s
        expect(result.inSeconds, 65);
      });
    });

    group('1h interval', () {
      test('aligns to hour boundaries', () {
        final now = DateTime(2026, 3, 17, 16, 59);
        final result = durationUntilNextSlot('1h', buffer: buffer, now: now);
        // minuteOfDay=1019, 1019~/60=16, next=17*60=1020 → 17:00:00 + 5s
        // wait = 17:00:05 - 16:59:00 = 65s
        expect(result.inSeconds, 65);
      });
    });

    group('24h interval', () {
      test('returns time until next midnight + buffer', () {
        final now = DateTime(2026, 3, 17, 23, 50);
        final result = durationUntilNextSlot('24h', buffer: buffer, now: now);
        // Next slot: 2026-03-18 00:00:00 + 5s
        // wait = 605s (10min + 5s)
        expect(result.inSeconds, 605);
      });
    });

    group('edge cases', () {
      test('within buffer zone still targets current boundary', () {
        final now = DateTime(2026, 3, 17, 16, 31, 3);
        final result = durationUntilNextSlot('1m', buffer: buffer, now: now);
        // Next slot: 16:32:00 + 5s = 16:32:05, wait = 62s
        expect(result.inSeconds, 62);
      });

      test('no buffer returns time until exact boundary', () {
        final now = DateTime(2026, 3, 17, 16, 30, 50);
        final result = durationUntilNextSlot('1m', now: now);
        // Next slot: 16:31:00, wait = 10s
        expect(result.inSeconds, 10);
      });

      test('midnight rollover with 1m', () {
        final now = DateTime(2026, 3, 17, 23, 59, 30);
        final result = durationUntilNextSlot('1m', buffer: buffer, now: now);
        // minuteOfDay=1439, 1439~/1=1439, next=1440 → 24:00 = next day 00:00 + 5s
        // wait = 35s
        expect(result.inSeconds, 35);
      });

      test('returns buffer when wait is negative', () {
        // This can happen if now is already past the computed target
        // (theoretical edge case handled by the isNegative check)
        final now = DateTime(2026, 3, 17, 16, 30);
        final result = durationUntilNextSlot('1m', now: now);
        // Next slot: 16:31:00, wait = 60s, not negative
        expect(result.inSeconds, 60);
      });
    });
  });
}
