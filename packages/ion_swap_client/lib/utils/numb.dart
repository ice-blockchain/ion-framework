// SPDX-License-Identifier: ice License 1.0

import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';

BigInt parseAmount(String amount, BigInt decimals) {
  final sanitized = amount.trim();
  if (sanitized.isEmpty) {
    throw const IonSwapException('Invalid amount format');
  }

  final parts = sanitized.split('.');
  if (parts.length < 2) {
    throw const IonSwapException('Invalid amount format');
  }

  final whole = parts[0].isEmpty ? '0' : parts[0];
  final fraction = parts.length > 1 ? parts[1] : '';

  final fractionPadded = fraction.padRight(decimals.toInt(), '0');
  final fractionCropped = fractionPadded.substring(0, decimals.toInt());

  final normalized = '$whole$fractionCropped';

  return BigInt.parse(normalized);
}
