// SPDX-License-Identifier: ice License 1.0

class EvmTransaction {
  EvmTransaction({
    required this.kind,
    required this.to,
    required this.data,
    required this.value,
    this.maxFeePerGas,
    this.maxPriorityFeePerGas,
  });

  final String kind;
  final String to;
  final String data;
  final BigInt value;
  final BigInt? maxFeePerGas;
  final BigInt? maxPriorityFeePerGas;
}
