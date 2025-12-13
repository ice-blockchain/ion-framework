// SPDX-License-Identifier: ice License 1.0

class SwapConstants {
  SwapConstants._();

  static final BigInt maxFeePerGas = BigInt.from(20000000000);
  static final BigInt maxPriorityFeePerGas = BigInt.from(1000000000);
  static const Duration delayAfterApproveDuration = Duration(seconds: 3);
}
