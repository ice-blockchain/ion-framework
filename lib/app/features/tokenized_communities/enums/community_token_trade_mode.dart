// SPDX-License-Identifier: ice License 1.0

enum CommunityTokenTradeMode {
  buy,
  sell;

  String get apiType => switch (this) {
        buy => 'buy',
        sell => 'sell',
      };
}
