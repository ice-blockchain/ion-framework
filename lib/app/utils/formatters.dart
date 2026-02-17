// SPDX-License-Identifier: ice License 1.0

import 'package:dlibphonenumber/dlibphonenumber.dart';

String toSubscript(int number) {
  final digits = number.toString();
  const subscriptMap = {
    '0': '₀',
    '1': '₁',
    '2': '₂',
    '3': '₃',
    '4': '₄',
    '5': '₅',
    '6': '₆',
    '7': '₇',
    '8': '₈',
    '9': '₉',
  };
  return digits.split('').map((d) => subscriptMap[d] ?? d).join();
}

// Formats a value using subscript notation for very small numbers.
// Returns a string like "$0.0₂25" for very small values (or "0.0₂25" without symbol).
String formatSubscriptNotation(double value, [String symbol = '']) {
  final absValue = value.abs();
  final expStr = absValue.toStringAsExponential(12);
  final match = RegExp(r'^(\d(?:\.\d+)?)e([+-]\d+)$').firstMatch(expStr);
  if (match == null) {
    return '';
  }

  final mantissaStr = match.group(1)!;
  final exponent = int.parse(match.group(2)!);
  final absExponent = exponent.abs();
  final zeroCount = absExponent - 1;

  final digits = mantissaStr.replaceAll('.', '');
  // Keep at most 2 significant digits for the trailing part
  var trailing = digits.length > 2 ? digits.substring(0, 2) : digits;
  trailing = trailing.replaceAll(RegExp(r'0+$'), '');
  if (trailing.isEmpty) trailing = '0';

  final sign = value < 0 ? '-' : '';
  return '$sign$symbol' '0.0' '${toSubscript(zeroCount)}' '$trailing';
}

// Formats a large number into a compact string representation.
// - 1000 -> 1K
// - 1234 -> 1.23K
// - 1234567 -> 1.23M
// - 1234567890 -> 1.23B
String formatCompactNumber(num value) {
  if (value >= 1e9) {
    return '${_formatCompactValue(value / 1e9)}B';
  } else if (value >= 1e6) {
    return '${_formatCompactValue(value / 1e6)}M';
  } else if (value >= 1e3) {
    return '${_formatCompactValue(value / 1e3)}K';
  } else if (value < 1) {
    return value.toStringAsFixed(2);
  }

  return value.toStringAsFixed(0);
}

String _formatCompactValue(num value) {
  final fixed = value.toStringAsFixed(2);
  return fixed.replaceAll(RegExp(r'\.?0+$'), '');
}

String formatTokenAmountWithSubscript(double value) {
  final absValue = value.abs();

  if (absValue == 0) return '0.00';

  if (absValue >= 1000) {
    return formatCompactNumber(value);
  }

  if (absValue >= 1) {
    return value.toStringAsFixed(2);
  }

  if (absValue >= 0.01) {
    return value.toStringAsFixed(2);
  }

  if (absValue >= 0.001) {
    final formatted = value.toStringAsFixed(4);
    return formatted.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  // Use shared subscript notation for very small values
  final subscript = formatSubscriptNotation(value);
  return subscript.isNotEmpty ? subscript : value.toStringAsFixed(6);
}

String obscureEmail(String email) {
  // Find the index of the '@' symbol.
  final atIndex = email.indexOf('@');
  if (atIndex == -1) return email; // Fallback: if email is malformed, return it unchanged.

  // Extract the local and domain parts.
  final localPart = email.substring(0, atIndex);
  final domainPart = email.substring(atIndex);

  // If the local part is 1 character, use it as-is.
  // Otherwise, take the last two characters.
  final visiblePart = localPart.length <= 1 ? localPart : localPart.substring(localPart.length - 2);

  // Prepend five asterisks and return the new email.
  return '*****$visiblePart$domainPart';
}

String obscurePhoneNumber(String phone) {
  // Determine prefix: if the phone starts with '+', take the first two characters;
  // otherwise, take the first character.
  final prefix = phone.startsWith('+')
      ? (phone.length >= 2 ? phone.substring(0, 2) : phone)
      : phone.substring(0, 1);

  // Determine suffix: if there are any characters beyond the prefix,
  // take the last two characters but make sure not to overlap the prefix.
  var suffix = '';
  if (phone.length > prefix.length) {
    var startIndex = phone.length - 2;
    // Ensure we don't start before the end of the prefix.
    if (startIndex < prefix.length) {
      startIndex = prefix.length;
    }
    suffix = phone.substring(startIndex);
  }

  return '$prefix*****$suffix';
}

String formatPhoneNumber(String countryCode, String phoneNumber) {
  return PhoneNumberUtil.instance.format(
    PhoneNumberUtil.instance.parse('$countryCode$phoneNumber', null),
    PhoneNumberFormat.e164,
  );
}
