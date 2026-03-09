double? calculatePriceImpact({
  required double sellAmount,
  required double sellPriceUSD,
  required double buyPriceUSD,
  required double exchangeRate,
}) {
  if (sellAmount <= 0 || sellPriceUSD <= 0 || buyPriceUSD <= 0) return null;

  final sellUsdValue = sellAmount * sellPriceUSD;
  final buyAmount = exchangeRate * sellAmount;
  final buyUsdValue = buyAmount * buyPriceUSD;

  return ((buyUsdValue - sellUsdValue) / sellUsdValue) * 100;
}
