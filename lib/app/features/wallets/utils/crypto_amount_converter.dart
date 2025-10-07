// SPDX-License-Identifier: ice License 1.0

import 'package:decimal/decimal.dart';
import 'package:ion/app/services/logger/logger.dart';

/// Converts a blockchain-precise numeric string (e.g., `"1000000000000000000"`)
/// into a human-readable Decimal value (e.g., `Decimal.parse('1.0')`).
double fromBlockchainUnits(String input, int decimals) {
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
