// SPDX-License-Identifier: ice License 1.0

import 'package:decimal/decimal.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/utils/num.dart';

/// Converts a blockchain-precise numeric string (e.g., `"1000000000000000000"`)
/// into a human-readable Decimal value (e.g., `Decimal.parse('1.0')`).
double fromBlockchainUnits(String input, {int decimals = 18}) {
  try {
    final value = BigInt.parse(input);
    final divisor = BigInt.from(10).pow(decimals);
    return (Decimal.fromBigInt(value) / Decimal.fromBigInt(divisor)).toDouble();
  } on FormatException catch (_) {
    Logger.error('Failed to parse coins amount with `$input` value.');
    return 0;
  }
}

/// Converts a human-readable double value (e.g., `1.23`)
/// into a blockchain-precise BigInt (e.g., `BigInt.parse('1230000000000000000')`).
BigInt toBlockchainUnits(double? amountValue, int decimals) {
  if (amountValue == null) return BigInt.zero;

  final decimal = Decimal.parse(amountValue.toString());
  final multiplier = BigInt.from(10).pow(decimals);
  return (decimal * Decimal.fromBigInt(multiplier)).toBigInt();
}

// Constants for scale values
const _million = 1000000.0;
const _billion = 1000000000.0;
const _trillion = 1000000000000.0;
const _minimalThreshold = 0.000001;

// Scale information for abbreviation formatting
const List<({double value, String suffix})> _scaleInfo = [
  (value: _trillion, suffix: 'T'),
  (value: _billion, suffix: 'B'),
  (value: _million, suffix: 'M'),
];

String formatCrypto(double value, [String? currency]) {
  // Normalize input values
  final normalized = switch (value) {
    _ when value <= 0 => 0.0,
    _ when value < _minimalThreshold => _minimalThreshold,
    _ => value,
  };

  final formatted = switch (normalized) {
    0.0 => formatDouble(normalized),
    _ when normalized >= _million => _formatWithAbbreviation(normalized),
    _ when normalized >= 10 =>
      _formatWithSmartTruncation(normalized, maxDecimals: 2, minDecimals: 2),
    // For values 1-9.99: max 6 decimals, min 2 decimals
    // Handle truncation for cases like 1.1234567 -> 1.123456 and 2.0000001 -> 2.00
    _ when normalized >= 1 =>
      _formatWithSmartTruncation(normalized, maxDecimals: 6, minDecimals: 2),
    // For values < 1: max 6 decimals, min 2 decimals
    _ => _formatWithSmartTruncation(normalized, maxDecimals: 6, minDecimals: 2),
  };

  if (currency != null) return '$formatted $currency';

  return formatted;
}

String _formatWithAbbreviation(double value) {
  // Find the appropriate scale
  final scale = _scaleInfo.firstWhere((scale) => value >= scale.value);
  final scaledValue = value / scale.value;

  // Convert to string and extract parts
  final stringValue = scaledValue.toString();
  final parts = stringValue.split('.');
  final integerPart = parts[0];

  if (parts.length == 1) {
    return '$integerPart${scale.suffix}';
  }

  final processedDecimal = _processDecimalPart(parts[1]);
  return processedDecimal.isEmpty
      ? '$integerPart${scale.suffix}'
      : '$integerPart.$processedDecimal${scale.suffix}';
}

String _processDecimalPart(String decimalPart) {
  // Truncate to maximum 3 decimal places
  final truncated = decimalPart.length > 3 ? decimalPart.substring(0, 3) : decimalPart;
  // Remove trailing zeros
  return truncated.replaceAll(RegExp(r'0+$'), '');
}

String _formatWithSmartTruncation(
  double value, {
  required int maxDecimals,
  required int minDecimals,
}) {
  final stringValue = value.toString();

  if (!stringValue.contains('.')) {
    // It's an integer, just format with minimum decimals
    return formatDouble(
      value,
      maximumFractionDigits: maxDecimals,
      minimumFractionDigits: minDecimals,
    );
  }

  final parts = stringValue.split('.');
  final integerPart = parts[0];
  var decimalPart = parts[1];

  // Truncate decimal part to maxDecimals if it's longer
  if (decimalPart.length > maxDecimals) {
    decimalPart = decimalPart.substring(0, maxDecimals);
  }

  // Pad with zeros to meet minimum decimals requirement
  final buffer = StringBuffer(decimalPart);
  while (buffer.length < minDecimals) {
    buffer.write('0');
  }
  decimalPart = buffer.toString();

  // Remove trailing zeros beyond minimum decimals
  while (decimalPart.length > minDecimals && decimalPart.endsWith('0')) {
    decimalPart = decimalPart.substring(0, decimalPart.length - 1);
  }

  final reconstructed = double.parse('$integerPart.$decimalPart');

  // Use formatDouble to get proper thousands separators
  return formatDouble(
    reconstructed,
    maximumFractionDigits: maxDecimals,
    minimumFractionDigits: minDecimals,
  );
}
