// SPDX-License-Identifier: ice License 1.0

import 'package:decimal/decimal.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

extension NumExtension on num? {
  num get zeroOrValue {
    return this ?? 0.0;
  }
}

extension IntNullableExtension on int? {
  int get zeroOrValue {
    return this ?? 0;
  }
}

extension DoubleNullableExtension on double? {
  double get zeroOrValue {
    return this ?? 0.0;
  }

  String removeDecimalZeroFormat({int roundToDecimalsCount = 2}) {
    final num noNullVal = zeroOrValue;
    return roundToDecimalsCount == 0
        ? noNullVal.truncateToDouble() == noNullVal
            ? noNullVal.toInt().toString()
            : toString()
        : noNullVal.toStringAsFixed(
            noNullVal.truncateToDouble() == noNullVal ? 0 : roundToDecimalsCount,
          );
  }

  String? get formatMax6 {
    final s = this?.toStringAsFixed(6);
    return s?.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  String formatWithDecimals(int decimals) {
    final noNullVal = zeroOrValue;
    final d = Decimal.parse(noNullVal.toString());
    final truncated = d.truncate(scale: decimals);
    final fixed = truncated.toStringAsFixed(decimals);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

extension SizeExtension on num {
  double get s {
    return w;
  }
}

extension Timestamp on int {
  DateTime get toDateTime {
    return DateTime.fromMicrosecondsSinceEpoch(toMicroseconds);
  }
}

extension Microseconds on int {
  int get toMicroseconds {
    return switch (toString().length) {
      // If the timestamp is 10 digits, it's in seconds
      10 => this * 1000000,
      // If the timestamp is 13 digits, it's in milliseconds
      13 => this * 1000,
      // If the timestamp is 16 digits, assume it's in microseconds
      16 => this,
      // If the timestamp is 19 digits, assume it's in nanoseconds
      19 => this ~/ 1000,
      _ => throw FormatException(
          'Invalid timestamp format: ${toString()} length: ${toString().length}',
        ),
    };
  }
}
