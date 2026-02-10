// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/transaction_crypto_asset.f.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/features/wallets/model/transaction_status.f.dart';
import 'package:ion/app/features/wallets/model/transaction_type.dart';

import 'fake_network_data.dart';

class FakeTransactionData {
  static TransactionData create({
    required String txHash,
    required String network,
    required TransactionType type,
    required TransactionStatus status,
    required String? senderWalletAddress,
    required String? receiverWalletAddress,
    String walletViewId = 'walletView1',
    String fee = '1',
    int? networkTier,
  }) {
    return TransactionData(
      txHash: txHash,
      walletViewId: walletViewId,
      network: _createNetworkData(network, networkTier),
      type: type,
      cryptoAsset: _createCryptoAsset(networkTier),
      senderWalletAddress: senderWalletAddress,
      receiverWalletAddress: receiverWalletAddress,
      fee: fee,
      status: status,
      index: '',
    );
  }

  static NetworkData _createNetworkData(String network, int? networkTier) {
    if (networkTier != null) {
      return NetworkData(
        id: network,
        image: 'image.png',
        isTestnet: false,
        displayName: 'Test Network',
        explorerUrl: 'https://explorer.test/{txHash}',
        tier: networkTier,
      );
    }
    return FakeNetworkData.create(
      id: network,
      isIonHistorySupported: network != 'network2',
    );
  }

  static TransactionCryptoAsset _createCryptoAsset(int? networkTier) {
    return TransactionCryptoAsset.coin(
      coin: CoinData(
        id: 'Test Coin',
        name: 'Test Coin',
        contractAddress: 'contractAddress',
        decimals: 18,
        iconUrl: 'image.png',
        abbreviation: 'TEST',
        network: networkTier != null
            ? NetworkData(
                id: 'network1',
                image: 'image.png',
                isTestnet: false,
                displayName: 'Test Network',
                explorerUrl: 'https://explorer.test/{txHash}',
                tier: networkTier,
              )
            : FakeNetworkData.create(
                id: 'network1',
                isIonHistorySupported: true,
              ),
        priceUSD: 0,
        symbolGroup: '',
        syncFrequency: const Duration(hours: 1),
      ),
      amount: 100,
      amountUSD: 100,
      rawAmount: '100',
    );
  }
}
