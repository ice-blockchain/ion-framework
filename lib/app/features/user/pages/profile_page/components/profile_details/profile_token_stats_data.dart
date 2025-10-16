// SPDX-License-Identifier: ice License 1.0

class ProfileTokenStatsData {
  const ProfileTokenStatsData({
    required this.marketCap,
    required this.price,
    required this.volume,
  });

  factory ProfileTokenStatsData.mock() {
    return const ProfileTokenStatsData(
      marketCap: '43.23M',
      price: r'$990',
      volume: '1.1K',
    );
  }

  final String marketCap;
  final String price;
  final String volume;
}
