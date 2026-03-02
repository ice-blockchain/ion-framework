// SPDX-License-Identifier: ice License 1.0

import 'package:decimal/decimal.dart';

/// Converts a human-readable double value (e.g., '1.23')
/// into a blockchain-precise (e.g., '1230000000000000000').
String toBlockchainUnits(String amount, int decimals) {
  if (amount.isEmpty) return '0';

  final decimal = Decimal.parse(amount);
  final multiplier = BigInt.from(10).pow(decimals);
  return (decimal * Decimal.fromBigInt(multiplier)).toBigInt().toString();
}
