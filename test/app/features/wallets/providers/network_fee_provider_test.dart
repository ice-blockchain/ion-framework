// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/network_fee_option.f.dart';
import 'package:ion/app/features/wallets/model/network_fee_type.dart';
import 'package:ion/app/features/wallets/providers/network_fee_provider.r.dart';
import 'package:ion_identity_client/ion_identity.dart' as ion;

void main() {
  group('NetworkFeeProvider', () {
    group('canUserCoverFee function', () {
      test('returns true when user has enough balance to cover fee', () {
        const networkNativeToken = ion.WalletAsset.native(
          symbol: 'BTC',
          balance: '100000000', // 1 BTC in satoshis
          decimals: 8,
          kind: 'Native',
        );
        const selectedFee = NetworkFeeOption(
          amount: 0.0001, // 0.0001 BTC
          priceUSD: 5,
          symbol: 'BTC',
          type: NetworkFeeType.standard,
        );

        expect(
          canUserCoverFee(
            selectedFee: selectedFee,
            networkNativeToken: networkNativeToken,
          ),
          isTrue,
        );
      });

      test('returns false when user does not have enough balance', () {
        const networkNativeToken = ion.WalletAsset.native(
          symbol: 'BTC',
          balance: '1000', // 0.00001 BTC in satoshis
          decimals: 8,
          kind: 'Native',
        );
        const selectedFee = NetworkFeeOption(
          amount: 0.0001, // 0.0001 BTC
          priceUSD: 5,
          symbol: 'BTC',
          type: NetworkFeeType.standard,
        );

        expect(
          canUserCoverFee(
            selectedFee: selectedFee,
            networkNativeToken: networkNativeToken,
          ),
          isFalse,
        );
      });

      test('returns false when networkNativeToken is null', () {
        const selectedFee = NetworkFeeOption(
          amount: 0.0001,
          priceUSD: 5,
          symbol: 'BTC',
          type: NetworkFeeType.standard,
        );

        expect(
          canUserCoverFee(
            selectedFee: selectedFee,
            networkNativeToken: null,
          ),
          isFalse,
        );
      });

      test('returns true when selectedFee is null and user has any balance', () {
        const networkNativeToken = ion.WalletAsset.native(
          symbol: 'ETH',
          balance: '1000000000000000', // Some ETH in wei
          decimals: 18,
          kind: 'Native',
        );

        expect(
          canUserCoverFee(
            selectedFee: null,
            networkNativeToken: networkNativeToken,
          ),
          isTrue,
        );
      });

      test('handles edge case with zero balance', () {
        const networkNativeToken = ion.WalletAsset.native(
          symbol: 'ETH',
          balance: '0', // Zero balance
          decimals: 18,
          kind: 'Native',
        );

        expect(
          canUserCoverFee(
            selectedFee: null,
            networkNativeToken: networkNativeToken,
          ),
          isFalse,
        );
      });

      test('handles balance conversion correctly for different decimals', () {
        const btcToken = ion.WalletAsset.native(
          symbol: 'BTC',
          balance: '50000000', // 0.5 BTC in satoshis
          decimals: 8,
          kind: 'Native',
        );
        const btcFee = NetworkFeeOption(
          amount: 0.0001, // 0.0001 BTC
          priceUSD: 5,
          symbol: 'BTC',
          type: NetworkFeeType.standard,
        );

        expect(
          canUserCoverFee(
            selectedFee: btcFee,
            networkNativeToken: btcToken,
          ),
          isTrue,
        );

        const ethToken = ion.WalletAsset.native(
          symbol: 'ETH',
          balance: '500000000000000000', // 0.5 ETH in wei
          decimals: 18,
          kind: 'Native',
        );
        const ethFee = NetworkFeeOption(
          amount: 0.0001, // 0.0001 ETH
          priceUSD: 0.3,
          symbol: 'ETH',
          type: NetworkFeeType.standard,
        );

        expect(
          canUserCoverFee(
            selectedFee: ethFee,
            networkNativeToken: ethToken,
          ),
          isTrue,
        );
      });

      test('returns true when balance is exactly equal to fee', () {
        const networkNativeToken = ion.WalletAsset.native(
          symbol: 'BTC',
          balance: '10000', // 0.0001 BTC in satoshis
          decimals: 8,
          kind: 'Native',
        );
        const selectedFee = NetworkFeeOption(
          amount: 0.0001, // 0.0001 BTC
          priceUSD: 5,
          symbol: 'BTC',
          type: NetworkFeeType.standard,
        );

        expect(
          canUserCoverFee(
            selectedFee: selectedFee,
            networkNativeToken: networkNativeToken,
          ),
          isTrue,
        );
      });

      test('handles very small amounts correctly', () {
        const networkNativeToken = ion.WalletAsset.native(
          symbol: 'ETH',
          balance: '1', // 1 wei
          decimals: 18,
          kind: 'Native',
        );
        const selectedFee = NetworkFeeOption(
          amount: 0.000000000000000001, // 1 wei in ETH
          priceUSD: 0.000000000000001,
          symbol: 'ETH',
          type: NetworkFeeType.standard,
        );

        expect(
          canUserCoverFee(
            selectedFee: selectedFee,
            networkNativeToken: networkNativeToken,
          ),
          isTrue,
        );
      });
    });

    group('buildNetworkFeeOptions function', () {
      late CoinData bitcoinCoin;
      late ion.WalletAsset bitcoinToken;
      late CoinData ethCoin;
      late ion.WalletAsset ethToken;

      setUp(() {
        bitcoinCoin = const CoinData(
          id: 'bitcoin',
          contractAddress: '',
          decimals: 8,
          iconUrl: '',
          name: 'Bitcoin',
          network: NetworkData(
            id: 'BitcoinSignet',
            image: 'bitcoin.svg',
            isTestnet: true,
            displayName: 'Bitcoin Signet',
            explorerUrl: '',
            tier: 1,
          ),
          priceUSD: 50000,
          abbreviation: 'BTC',
          symbolGroup: 'BTC',
          syncFrequency: Duration(minutes: 5),
          native: true,
        );

        ethCoin = const CoinData(
          id: 'ethereum',
          contractAddress: '',
          decimals: 18,
          iconUrl: 'ethereum.svg',
          name: 'Ethereum',
          network: NetworkData(
            id: 'EthereumSepolia',
            image: 'ethereum.svg',
            isTestnet: true,
            displayName: 'Ethereum',
            explorerUrl: '',
            tier: 1,
          ),
          priceUSD: 1000,
          abbreviation: 'ETH',
          symbolGroup: 'ETH',
          syncFrequency: Duration(minutes: 5),
          native: true,
        );

        bitcoinToken = const ion.WalletAsset.native(
          symbol: 'BTC',
          balance: '100000000',
          decimals: 8,
          kind: 'Native',
        );

        ethToken = const ion.WalletAsset.native(
          symbol: 'ETH',
          balance: '1000000000000000',
          decimals: 18,
          kind: 'Native',
        );
      });

      test('returns all fee options when all are present', () {
        final estimateFees = ion.EstimateFee(
          network: 'BitcoinSignet',
          kind: 'Bitcoin',
          slow: const ion.NetworkFee(feeRate: '2.0'),
          standard: const ion.NetworkFee(feeRate: '10.0'),
          fast: const ion.NetworkFee(feeRate: '40.0'),
        );

        final result = buildNetworkFeeOptions(
          estimateFees: estimateFees,
          nativeCoin: bitcoinCoin,
          networkNativeToken: bitcoinToken,
        );

        expect(result, hasLength(3));
        expect(result[0].type, NetworkFeeType.slow);
        expect(result[1].type, NetworkFeeType.standard);
        expect(result[2].type, NetworkFeeType.fast);
      });

      test('returns only available fee options when some are null', () {
        final estimateFees = ion.EstimateFee(
          network: 'BitcoinSignet',
          kind: 'Bitcoin',
          standard: const ion.NetworkFee(feeRate: '10.0'),
          fast: const ion.NetworkFee(feeRate: '40.0'),
        );

        final result = buildNetworkFeeOptions(
          estimateFees: estimateFees,
          nativeCoin: bitcoinCoin,
          networkNativeToken: bitcoinToken,
        );

        expect(result, hasLength(2));
        expect(result[0].type, NetworkFeeType.standard);
        expect(result[1].type, NetworkFeeType.fast);
      });

      test('returns empty list when no fee options are available', () {
        final estimateFees = ion.EstimateFee(
          network: 'BitcoinSignet',
          kind: 'Bitcoin',
        );

        final result = buildNetworkFeeOptions(
          estimateFees: estimateFees,
          nativeCoin: bitcoinCoin,
          networkNativeToken: bitcoinToken,
        );

        expect(result, isEmpty);
      });

      test('maintains correct ordering (slow, standard, fast)', () {
        final estimateFees = ion.EstimateFee(
          network: 'BitcoinSignet',
          kind: 'Bitcoin',
          slow: const ion.NetworkFee(feeRate: '2.0'),
          standard: const ion.NetworkFee(feeRate: '10.0'),
          fast: const ion.NetworkFee(feeRate: '40.0'),
        );

        final result = buildNetworkFeeOptions(
          estimateFees: estimateFees,
          nativeCoin: bitcoinCoin,
          networkNativeToken: bitcoinToken,
        );

        expect(result, hasLength(3));
        expect(result[0].type, NetworkFeeType.slow);
        expect(result[1].type, NetworkFeeType.standard);
        expect(result[2].type, NetworkFeeType.fast);
      });

      test('correctly calculates BTC fee amounts and USD price for slow, standard, fast', () {
        final estimateFees = ion.EstimateFee(
          network: 'BitcoinSignet',
          kind: 'Bitcoin',
          slow: const ion.NetworkFee(feeRate: '2'), // sats/vByte
          standard: const ion.NetworkFee(feeRate: '10'),
          fast: const ion.NetworkFee(feeRate: '40'),
        );

        final result = buildNetworkFeeOptions(
          estimateFees: estimateFees,
          nativeCoin: bitcoinCoin,
          networkNativeToken: bitcoinToken,
        );

        expect(result, hasLength(3));

        // Helper to compute BTC fee
        double satsToBtc(double satsPerVByte) {
          const txSize = 250.0;
          const satsPerBtc = 100000000;
          return (satsPerVByte * txSize) / satsPerBtc;
        }

        final slowAmount = satsToBtc(2);
        final standardAmount = satsToBtc(10);
        final fastAmount = satsToBtc(40);

        expect(result[0].amount, closeTo(slowAmount, 1e-12));
        expect(result[0].priceUSD, closeTo(slowAmount * 50000, 1e-6));

        expect(result[1].amount, closeTo(standardAmount, 1e-12));
        expect(result[1].priceUSD, closeTo(standardAmount * 50000, 1e-6));

        expect(result[2].amount, closeTo(fastAmount, 1e-12));
        expect(result[2].priceUSD, closeTo(fastAmount * 50000, 1e-6));
      });

      test('correctly calculates ETH fee amounts and USD price for slow, standard, fast', () {
        final estimateFees = ion.EstimateFee(
          network: 'EthereumSepolia',
          kind: 'Ethereum',
          slow: const ion.NetworkFee(maxFeePerGas: '10000000000'), // 10 gwei
          standard: const ion.NetworkFee(maxFeePerGas: '20000000000'), // 20 gwei
          fast: const ion.NetworkFee(maxFeePerGas: '40000000000'), // 40 gwei
        );

        final result = buildNetworkFeeOptions(
          estimateFees: estimateFees,
          nativeCoin: ethCoin,
          networkNativeToken: ethToken,
        );

        expect(result, hasLength(3));

        // Helper to compute ETH fee
        double weiToEth(double wei) => wei / 1e18;

        final slowAmount = weiToEth(10000000000);
        final standardAmount = weiToEth(20000000000);
        final fastAmount = weiToEth(40000000000);

        expect(result[0].amount, closeTo(slowAmount, 1e-20));
        expect(result[0].priceUSD, closeTo(slowAmount * 1000, 1e-15));

        expect(result[1].amount, closeTo(standardAmount, 1e-20));
        expect(result[1].priceUSD, closeTo(standardAmount * 1000, 1e-15));

        expect(result[2].amount, closeTo(fastAmount, 1e-20));
        expect(result[2].priceUSD, closeTo(fastAmount * 1000, 1e-15));
      });

      test('returns 0 fee amount and priceUSD for slow, standard, fast when no fee info', () {
        final estimateFees = ion.EstimateFee(
          network: 'EthereumSepolia',
          kind: 'Ethereum',
          slow: const ion.NetworkFee(), // no feeRate or maxFeePerGas
          standard: const ion.NetworkFee(),
          fast: const ion.NetworkFee(),
        );

        final result = buildNetworkFeeOptions(
          estimateFees: estimateFees,
          nativeCoin: ethCoin,
          networkNativeToken: ethToken,
        );

        expect(result, hasLength(3));

        for (final option in result) {
          expect(option.amount, 0);
          expect(option.priceUSD, 0);
          expect(option.symbol, 'ETH');
        }
      });
    });
  });
}
