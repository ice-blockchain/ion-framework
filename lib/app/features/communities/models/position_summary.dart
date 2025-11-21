// SPDX-License-Identifier: ice License 1.0

class PositionSummary {
  const PositionSummary({
    required this.changeAmountUsd,
    required this.changePercent,
    required this.circulatingSupply,
    required this.priceUsd,
  });

  final double changeAmountUsd;
  final double changePercent;
  final num circulatingSupply;
  final double priceUsd;
}
