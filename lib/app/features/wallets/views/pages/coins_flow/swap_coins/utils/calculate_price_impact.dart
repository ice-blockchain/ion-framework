double? calculatePriceImpact({
  required double sellAmount,
  required double buyAmount,
  required double sellPriceUsd,
  required double buyPriceUsd,
}) {
  if (sellAmount == 0 || buyAmount == 0 || buyPriceUsd == 0) return null;

  final executionPrice = buyAmount / sellAmount;
  final spotPrice = sellPriceUsd / buyPriceUsd;

  final impact = -((spotPrice - executionPrice) / spotPrice) * 100;

  if (impact.abs() < 0.000001) return 0;

  return impact;
}
