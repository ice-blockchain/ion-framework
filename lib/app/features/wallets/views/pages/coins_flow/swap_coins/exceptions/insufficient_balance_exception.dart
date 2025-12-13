// SPDX-License-Identifier: ice License 1.0

final class InsufficientBalanceException implements Exception {}

final class AmountBelowMinimumException implements Exception {
  AmountBelowMinimumException({required this.symbol, required this.minAmount});

  final String symbol;
  final String minAmount;
}
