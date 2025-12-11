// SPDX-License-Identifier: ice License 1.0

/// Converts a human-readable double value (e.g., '1.23')
/// into a blockchain-precise (e.g., '1230000000000000000').
String toBlockchainUnits(String amount, int decimals) {
  return (BigInt.from(double.parse(amount)) * BigInt.from(10).pow(decimals)).toString();
}
