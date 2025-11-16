// SPDX-License-Identifier: ice License 1.0

enum TradeSide { buy, sell }

class LatestTrade {
  const LatestTrade({
    required this.displayName,
    required this.handle,
    required this.amount,
    required this.usd,
    required this.time,
    required this.side,
    this.avatarUrl,
    this.verified = false,
  });

  final String displayName;
  final String handle; // can be empty for address-only
  final String? avatarUrl;
  final double amount;
  final double usd;
  final DateTime time;
  final TradeSide side;
  final bool verified;
}
