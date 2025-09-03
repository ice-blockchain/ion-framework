// SPDX-License-Identifier: ice License 1.0

part of 'sync_transactions_service_test.dart';

class MockNetworksRepository extends Mock implements NetworksRepository {}

class MockCryptoWalletsRepository extends Mock implements CryptoWalletsRepository {}

class MockTransactionLoader extends Mock implements TransactionLoader {}

class MockTransferStatusUpdater extends Mock implements TransferStatusUpdater {}

class MockWalletViewsService extends Mock implements WalletViewsService {}

class MockTransactionsRepository extends Mock implements TransactionsRepository {}

class MockTransactionsVisibilityCloudBackup extends Mock implements TransactionsVisibilityCloudBackup {}

/// Contains common setup methods for tests
class MockSetupHelper {
  static void setupNetworkMocks(
    MockNetworksRepository mockNetworksRepository, {
    List<String> networkIds = const ['network1', 'network2', 'network3', 'network4'],
    List<bool> ionHistorySupported = const [true, true, true, true],
  }) {
    final networks = <String, NetworkData>{};
    for (var i = 0; i < networkIds.length; i++) {
      networks[networkIds[i]] = FakeNetworkData.create(
        id: networkIds[i],
        isIonHistorySupported: ionHistorySupported.length > i && ionHistorySupported[i],
      );
    }

    when(() => mockNetworksRepository.getAllAsMap()).thenAnswer((_) async => networks);
  }

  static void setupWalletViewsMocks(
    MockWalletViewsService mockWalletViewsService, {
    List<String> walletIds = const ['wallet1', 'wallet2', 'wallet3', 'wallet4'],
    List<String> symbolGroups = const ['BTC', 'ETH', 'SOL', 'ADA'],
    List<String>? networkIds,
  }) {
    final walletViews = <WalletViewData>[];
    for (var i = 0; i < walletIds.length; i++) {
      walletViews.add(
        FakeWalletViewData.create(
          id: 'walletView${i + 1}',
          walletId: walletIds[i],
          symbolGroup: symbolGroups.length > i ? symbolGroups[i] : 'DEFAULT',
          networkId: networkIds?.length != null && networkIds!.length > i
              ? networkIds[i]
              : 'network${i + 1}',
        ),
      );
    }

    when(() => mockWalletViewsService.lastEmitted).thenReturn(walletViews);
    when(() => mockWalletViewsService.walletViews).thenAnswer((_) => Stream.value(walletViews));
  }

  static void setupTransactionLoaderMocks(
    MockTransactionLoader mockTransactionLoader, {
    bool returnValue = false,
  }) {
    when(
      () => mockTransactionLoader.load(
        wallet: any(named: 'wallet'),
        walletViewId: any(named: 'walletViewId'),
        isFullLoad: any(named: 'isFullLoad'),
      ),
    ).thenAnswer((_) async => returnValue);
  }

  static void setupCryptoWalletMocks(
    MockCryptoWalletsRepository mockCryptoWalletsRepository, {
    bool isHistoryLoaded = false,
  }) {
    when(
      () => mockCryptoWalletsRepository.isHistoryLoadedForWallet(
        walletId: any(named: 'walletId'),
      ),
    ).thenAnswer((_) async => isHistoryLoaded);

    when(
      () => mockCryptoWalletsRepository.save(
        wallet: any(named: 'wallet'),
        isHistoryLoaded: any(named: 'isHistoryLoaded'),
      ),
    ).thenAnswer((_) async {});
  }

  static void setupTransferStatusUpdaterMocks(
    MockTransferStatusUpdater mockTransferStatusUpdater,
  ) {
    when(() => mockTransferStatusUpdater.update(any())).thenAnswer((_) async {});
  }

  static List<TransactionData> createBroadcastedTransfersTestData() {
    return [
      FakeTransactionData.create(
        txHash: 'tx1',
        network: 'network1',
        type: TransactionType.send,
        status: TransactionStatus.broadcasted,
        senderWalletAddress: 'address1',
        receiverWalletAddress: 'other1',
      ),
      FakeTransactionData.create(
        txHash: 'tx2',
        network: 'network2',
        type: TransactionType.send,
        status: TransactionStatus.executing,
        senderWalletAddress: 'address2',
        receiverWalletAddress: 'other2',
      ),
      FakeTransactionData.create(
        txHash: 'tx3',
        network: 'network3',
        type: TransactionType.receive,
        status: TransactionStatus.pending,
        senderWalletAddress: 'other3',
        receiverWalletAddress: 'address3',
      ),
      FakeTransactionData.create(
        txHash: 'tx4',
        network: 'network4',
        type: TransactionType.receive,
        status: TransactionStatus.broadcasted,
        senderWalletAddress: 'other4',
        receiverWalletAddress: 'address4',
      ),
      FakeTransactionData.create(
        txHash: 'tx5',
        network: 'network1',
        type: TransactionType.send,
        status: TransactionStatus.executing,
        senderWalletAddress: 'unknown_address',
        receiverWalletAddress: 'other5',
      ),
      FakeTransactionData.create(
        txHash: 'tx6',
        network: 'network1',
        type: TransactionType.send,
        status: TransactionStatus.broadcasted,
        senderWalletAddress: null,
        receiverWalletAddress: 'other6',
      ),
    ];
  }
}
