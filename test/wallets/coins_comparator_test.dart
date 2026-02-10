// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/wallets/domain/coins/coins_comparator.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coin_in_wallet_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';

NetworkData _createNetwork({String displayName = 'TestNetwork'}) {
  return NetworkData(
    id: 'test-network-id',
    image: 'https://example.com/image.png',
    isTestnet: false,
    displayName: displayName,
    explorerUrl: 'https://explorer.example.com/{txHash}',
    tier: 1,
  );
}

CoinData _createCoin({
  required String symbolGroup,
  String? name,
  String abbreviation = 'TEST',
  NetworkData? network,
  bool native = false,
  bool prioritized = false,
}) {
  return CoinData(
    id: 'coin-$symbolGroup',
    contractAddress: '0x123',
    decimals: 18,
    iconUrl: 'https://example.com/icon.png',
    name: name ?? symbolGroup.toUpperCase(),
    network: network ?? _createNetwork(),
    priceUSD: 1,
    abbreviation: abbreviation,
    symbolGroup: symbolGroup,
    syncFrequency: const Duration(seconds: 30),
    native: native,
    prioritized: prioritized,
  );
}

CoinInWalletData _createCoinInWallet({
  required String symbolGroup,
  double balanceUSD = 0,
  NetworkData? network,
  bool native = false,
  bool prioritized = false,
}) {
  return CoinInWalletData(
    coin: _createCoin(
      symbolGroup: symbolGroup,
      network: network,
      native: native,
      prioritized: prioritized,
    ),
    balanceUSD: balanceUSD,
  );
}

CoinsGroup _createCoinsGroup({
  required String symbolGroup,
  double totalBalanceUSD = 0,
}) {
  return CoinsGroup(
    name: symbolGroup.toUpperCase(),
    symbolGroup: symbolGroup,
    abbreviation: symbolGroup.toUpperCase(),
    coins: [],
    totalBalanceUSD: totalBalanceUSD,
  );
}

void main() {
  late CoinsComparator comparator;

  setUp(() {
    comparator = CoinsComparator();
  });

  group('CoinsComparator', () {
    group('ION priority', () {
      test('ION always comes first regardless of balance', () {
        final ion = _createCoinsGroup(symbolGroup: 'ion');
        final btc = _createCoinsGroup(symbolGroup: 'bitcoin', totalBalanceUSD: 1000);

        expect(comparator.compareGroups(ion, btc), lessThan(0));
        expect(comparator.compareGroups(btc, ion), greaterThan(0));
      });

      test('ION comes before ICE (OLD) even when ICE has higher balance', () {
        final ion = _createCoinsGroup(symbolGroup: 'ion');
        final iceOld = _createCoinsGroup(symbolGroup: 'ice', totalBalanceUSD: 1000);

        expect(comparator.compareGroups(ion, iceOld), lessThan(0));
        expect(comparator.compareGroups(iceOld, ion), greaterThan(0));
      });

      test('ION priority is case insensitive', () {
        final ionLower = _createCoinsGroup(symbolGroup: 'ion');
        final ionUpper = _createCoinsGroup(symbolGroup: 'ION');
        final btc = _createCoinsGroup(symbolGroup: 'bitcoin', totalBalanceUSD: 1000);

        expect(comparator.compareGroups(ionLower, btc), lessThan(0));
        expect(comparator.compareGroups(ionUpper, btc), lessThan(0));
      });
    });

    group('ICE (OLD) with low balance', () {
      test('ICE (OLD) with zero balance goes to end of list', () {
        final iceOld = _createCoinsGroup(symbolGroup: 'ice');
        final btc = _createCoinsGroup(symbolGroup: 'bitcoin', totalBalanceUSD: 100);

        expect(comparator.compareGroups(iceOld, btc), greaterThan(0));
        expect(comparator.compareGroups(btc, iceOld), lessThan(0));
      });

      test('ICE (OLD) with balance 0.005 goes to end of list', () {
        final iceOld = _createCoinsGroup(symbolGroup: 'ice', totalBalanceUSD: 0.005);
        final btc = _createCoinsGroup(symbolGroup: 'bitcoin', totalBalanceUSD: 100);

        expect(comparator.compareGroups(iceOld, btc), greaterThan(0));
        expect(comparator.compareGroups(btc, iceOld), lessThan(0));
      });

      test('ICE (OLD) with balance 0.009 goes to end of list', () {
        final iceOld = _createCoinsGroup(symbolGroup: 'ice', totalBalanceUSD: 0.009);
        final btc = _createCoinsGroup(symbolGroup: 'bitcoin', totalBalanceUSD: 100);

        expect(comparator.compareGroups(iceOld, btc), greaterThan(0));
        expect(comparator.compareGroups(btc, iceOld), lessThan(0));
      });

      test('ICE (OLD) with low balance comes after regular coins with any balance', () {
        final iceOld = _createCoinsGroup(symbolGroup: 'ice', totalBalanceUSD: 0.005);
        final lowBalanceCoin = _createCoinsGroup(
          symbolGroup: 'some-token',
          totalBalanceUSD: 0.01,
        );

        expect(comparator.compareGroups(iceOld, lowBalanceCoin), greaterThan(0));
        expect(comparator.compareGroups(lowBalanceCoin, iceOld), lessThan(0));
      });

      test('ICE (OLD) with low balance comes after coins with zero balance', () {
        final iceOld = _createCoinsGroup(symbolGroup: 'ice');
        final otherCoin = _createCoinsGroup(symbolGroup: 'other-coin');

        expect(comparator.compareGroups(iceOld, otherCoin), greaterThan(0));
        expect(comparator.compareGroups(otherCoin, iceOld), lessThan(0));
      });

      test('two ICE (OLD) coins with same low balance are equal', () {
        final iceOld1 = _createCoinsGroup(symbolGroup: 'ice', totalBalanceUSD: 0.005);
        final iceOld2 = _createCoinsGroup(symbolGroup: 'ICE', totalBalanceUSD: 0.005);

        expect(comparator.compareGroups(iceOld1, iceOld2), equals(0));
      });

      test('ICE (OLD) low balance check is case insensitive', () {
        final iceOldLower = _createCoinsGroup(symbolGroup: 'ice', totalBalanceUSD: 0.005);
        final iceOldUpper = _createCoinsGroup(symbolGroup: 'ICE', totalBalanceUSD: 0.009);
        final btc = _createCoinsGroup(symbolGroup: 'bitcoin', totalBalanceUSD: 100);

        expect(comparator.compareGroups(iceOldLower, btc), greaterThan(0));
        expect(comparator.compareGroups(iceOldUpper, btc), greaterThan(0));
      });
    });

    group('ICE (OLD) with balance >= 0.01', () {
      test('ICE (OLD) with balance exactly 0.01 is sorted normally', () {
        final iceOld = _createCoinsGroup(symbolGroup: 'ice', totalBalanceUSD: 0.01);
        final lowBalanceCoin = _createCoinsGroup(
          symbolGroup: 'some-token',
          totalBalanceUSD: 0.005,
        );

        expect(comparator.compareGroups(iceOld, lowBalanceCoin), lessThan(0));
        expect(comparator.compareGroups(lowBalanceCoin, iceOld), greaterThan(0));
      });

      test('ICE (OLD) with balance 0.02 is sorted normally', () {
        final iceOld = _createCoinsGroup(symbolGroup: 'ice', totalBalanceUSD: 0.02);
        final lowBalanceCoin = _createCoinsGroup(
          symbolGroup: 'some-token',
          totalBalanceUSD: 0.01,
        );

        expect(comparator.compareGroups(iceOld, lowBalanceCoin), lessThan(0));
        expect(comparator.compareGroups(lowBalanceCoin, iceOld), greaterThan(0));
      });

      test('ICE (OLD) with balance > 0.01 is sorted by USD value (normal sorting)', () {
        final iceOld = _createCoinsGroup(symbolGroup: 'ice', totalBalanceUSD: 500);
        final btc = _createCoinsGroup(symbolGroup: 'bitcoin', totalBalanceUSD: 100);

        expect(comparator.compareGroups(iceOld, btc), lessThan(0));
        expect(comparator.compareGroups(btc, iceOld), greaterThan(0));
      });

      test('ICE (OLD) with high balance comes before coins with lower balance', () {
        final iceOld = _createCoinsGroup(symbolGroup: 'ice', totalBalanceUSD: 1000);
        final eth = _createCoinsGroup(symbolGroup: 'ethereum', totalBalanceUSD: 500);
        final sol = _createCoinsGroup(symbolGroup: 'solana', totalBalanceUSD: 200);

        expect(comparator.compareGroups(iceOld, eth), lessThan(0));
        expect(comparator.compareGroups(iceOld, sol), lessThan(0));
      });

      test('ICE (OLD) with balance comes after coins with higher balance', () {
        final iceOld = _createCoinsGroup(symbolGroup: 'ice', totalBalanceUSD: 100);
        final btc = _createCoinsGroup(symbolGroup: 'bitcoin', totalBalanceUSD: 1000);

        expect(comparator.compareGroups(iceOld, btc), greaterThan(0));
        expect(comparator.compareGroups(btc, iceOld), lessThan(0));
      });

      test('ICE (OLD) with balance >= 0.01 still comes after ION', () {
        final ion = _createCoinsGroup(symbolGroup: 'ion');
        final iceOld = _createCoinsGroup(symbolGroup: 'ice', totalBalanceUSD: 10000);

        expect(comparator.compareGroups(ion, iceOld), lessThan(0));
        expect(comparator.compareGroups(iceOld, ion), greaterThan(0));
      });
    });

    group('compareGroups', () {
      test('sorts by totalBalanceUSD in descending order', () {
        final high = _createCoinsGroup(symbolGroup: 'high', totalBalanceUSD: 1000);
        final low = _createCoinsGroup(symbolGroup: 'low', totalBalanceUSD: 100);

        expect(comparator.compareGroups(high, low), lessThan(0));
        expect(comparator.compareGroups(low, high), greaterThan(0));
      });

      test('equal balances fall through to priority list', () {
        final btc = _createCoinsGroup(symbolGroup: 'bitcoin', totalBalanceUSD: 100);
        final eth = _createCoinsGroup(symbolGroup: 'ethereum', totalBalanceUSD: 100);

        expect(comparator.compareGroups(btc, eth), lessThan(0));
      });

      test('ICE (OLD) with low balance goes to end even when other coins have zero', () {
        final iceOld = _createCoinsGroup(symbolGroup: 'ice');
        final randomCoin = _createCoinsGroup(symbolGroup: 'random');

        expect(comparator.compareGroups(iceOld, randomCoin), greaterThan(0));
      });

      test('priority list coins come before non-priority coins with same balance', () {
        final btc = _createCoinsGroup(symbolGroup: 'bitcoin', totalBalanceUSD: 100);
        final unknown = _createCoinsGroup(symbolGroup: 'unknown-coin', totalBalanceUSD: 100);

        expect(comparator.compareGroups(btc, unknown), lessThan(0));
        expect(comparator.compareGroups(unknown, btc), greaterThan(0));
      });
    });

    group('compareCoins', () {
      test('sorts CoinInWalletData by balanceUSD in descending order', () {
        final high = _createCoinInWallet(symbolGroup: 'high', balanceUSD: 1000);
        final low = _createCoinInWallet(symbolGroup: 'low', balanceUSD: 100);

        expect(comparator.compareCoins(high, low), lessThan(0));
        expect(comparator.compareCoins(low, high), greaterThan(0));
      });

      test('ICE (OLD) with low balance goes to end', () {
        final iceOld = _createCoinInWallet(symbolGroup: 'ice', balanceUSD: 0.005);
        final other = _createCoinInWallet(symbolGroup: 'other', balanceUSD: 100);

        expect(comparator.compareCoins(iceOld, other), greaterThan(0));
        expect(comparator.compareCoins(other, iceOld), lessThan(0));
      });

      test('ICE (OLD) with balance >= 0.01 is sorted normally', () {
        final iceOld = _createCoinInWallet(symbolGroup: 'ice', balanceUSD: 0.01);
        final other = _createCoinInWallet(symbolGroup: 'other', balanceUSD: 0.005);

        expect(comparator.compareCoins(iceOld, other), lessThan(0));
      });

      test('prioritized coins come before non-prioritized with same balance', () {
        final prioritized = _createCoinInWallet(
          symbolGroup: 'coin-a',
          balanceUSD: 100,
          prioritized: true,
        );
        final normal = _createCoinInWallet(
          symbolGroup: 'coin-b',
          balanceUSD: 100,
        );

        expect(comparator.compareCoins(prioritized, normal), lessThan(0));
        expect(comparator.compareCoins(normal, prioritized), greaterThan(0));
      });

      test('native coins come before non-native with same symbol group', () {
        final nativeCoin = _createCoinInWallet(
          symbolGroup: 'eth',
          balanceUSD: 100,
          native: true,
          network: _createNetwork(displayName: 'Ethereum'),
        );
        final token = _createCoinInWallet(
          symbolGroup: 'eth',
          balanceUSD: 100,
          network: _createNetwork(displayName: 'Polygon'),
        );

        expect(comparator.compareCoins(nativeCoin, token), lessThan(0));
        expect(comparator.compareCoins(token, nativeCoin), greaterThan(0));
      });

      test('coins with same symbolGroup and balance are sorted by network name', () {
        final coinOnEthereum = _createCoinInWallet(
          symbolGroup: 'usdt',
          balanceUSD: 100,
          network: _createNetwork(displayName: 'Ethereum'),
        );
        final coinOnPolygon = _createCoinInWallet(
          symbolGroup: 'usdt',
          balanceUSD: 100,
          network: _createNetwork(displayName: 'Polygon'),
        );

        expect(comparator.compareCoins(coinOnEthereum, coinOnPolygon), lessThan(0));
        expect(comparator.compareCoins(coinOnPolygon, coinOnEthereum), greaterThan(0));
      });

      test('ION always comes first', () {
        final ion = _createCoinInWallet(symbolGroup: 'ion');
        final btc = _createCoinInWallet(symbolGroup: 'bitcoin', balanceUSD: 1000);

        expect(comparator.compareCoins(ion, btc), lessThan(0));
        expect(comparator.compareCoins(btc, ion), greaterThan(0));
      });
    });

    group('sorting a list', () {
      test('correctly sorts a mixed list with ION, ICE (OLD) low balance, and regular coins', () {
        final groups = [
          _createCoinsGroup(symbolGroup: 'ethereum', totalBalanceUSD: 500),
          _createCoinsGroup(symbolGroup: 'ice', totalBalanceUSD: 0.005),
          _createCoinsGroup(symbolGroup: 'bitcoin', totalBalanceUSD: 1000),
          _createCoinsGroup(symbolGroup: 'ion', totalBalanceUSD: 10),
          _createCoinsGroup(symbolGroup: 'solana', totalBalanceUSD: 200),
        ]..sort(comparator.compareGroups);

        expect(groups[0].symbolGroup, equals('ion'));
        expect(groups[1].symbolGroup, equals('bitcoin'));
        expect(groups[2].symbolGroup, equals('ethereum'));
        expect(groups[3].symbolGroup, equals('solana'));
        expect(groups[4].symbolGroup, equals('ice'));
      });

      test('correctly sorts when ICE (OLD) has balance >= 0.01', () {
        final groups = [
          _createCoinsGroup(symbolGroup: 'ethereum', totalBalanceUSD: 500),
          _createCoinsGroup(symbolGroup: 'ice', totalBalanceUSD: 800),
          _createCoinsGroup(symbolGroup: 'bitcoin', totalBalanceUSD: 1000),
          _createCoinsGroup(symbolGroup: 'ion', totalBalanceUSD: 10),
        ]..sort(comparator.compareGroups);

        expect(groups[0].symbolGroup, equals('ion'));
        expect(groups[1].symbolGroup, equals('bitcoin'));
        expect(groups[2].symbolGroup, equals('ice'));
        expect(groups[3].symbolGroup, equals('ethereum'));
      });
    });
  });
}
