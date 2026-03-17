// SPDX-License-Identifier: ice License 1.0

// Parses an interval string (e.g. "1m", "15m", "1h", "24h") into a [Duration].
Duration parseIntervalDuration(String interval) {
  final value = int.parse(interval.substring(0, interval.length - 1));
  if (interval.endsWith('h')) return Duration(hours: value);
  return Duration(minutes: value);
}

/// Returns duration until the next interval boundary + [buffer].
/// Aligns to clean clock boundaries (e.g. :00, :05, :15 for minute intervals).
/// The [buffer] gives BE a chance to send real data before a tick fires.
Duration durationUntilNextSlot(
  String interval, {
  Duration buffer = Duration.zero,
  DateTime? now,
}) {
  final effectiveNow = now ?? DateTime.now();
  final duration = parseIntervalDuration(interval);

  final DateTime nextSlot;
  if (duration.inHours < 24) {
    final minutes = duration.inMinutes;
    final minuteOfDay = effectiveNow.hour * 60 + effectiveNow.minute;
    final nextMinute = (minuteOfDay ~/ minutes + 1) * minutes;
    nextSlot = DateTime(effectiveNow.year, effectiveNow.month, effectiveNow.day)
        .add(Duration(minutes: nextMinute));
  } else {
    nextSlot = DateTime(effectiveNow.year, effectiveNow.month, effectiveNow.day + 1);
  }

  final wait = nextSlot.add(buffer).difference(effectiveNow);
  return wait.isNegative ? buffer : wait;
}
