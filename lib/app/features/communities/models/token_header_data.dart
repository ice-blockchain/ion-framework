// SPDX-License-Identifier: ice License 1.0

class TokenHeaderData {
  const TokenHeaderData({
    required this.displayName,
    required this.handle,
    required this.priceUsd,
    required this.marketCapUsd,
    required this.holdersCount,
    required this.volumeUsd,
    this.verified = false,
  });

  final String displayName;
  final String handle;
  final double priceUsd;
  final double marketCapUsd;
  final int holdersCount;
  final double volumeUsd;
  final bool verified;
}
