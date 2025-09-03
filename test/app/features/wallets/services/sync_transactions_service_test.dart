// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/wallets/data/repository/crypto_wallets_repository.r.dart';
import 'package:ion/app/features/wallets/data/repository/networks_repository.r.dart';
import 'package:ion/app/features/wallets/data/repository/transactions_repository.m.dart';
import 'package:ion/app/features/wallets/domain/transactions/sync_transactions_service.r.dart';
import 'package:ion/app/features/wallets/domain/transactions/transaction_loader.r.dart';
import 'package:ion/app/features/wallets/domain/transactions/transfer_status_updater.r.dart';
import 'package:ion/app/features/wallets/domain/wallet_views/wallet_views_service.r.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/features/wallets/model/transaction_status.f.dart';
import 'package:ion/app/features/wallets/model/transaction_type.dart';
import 'package:ion/app/features/wallets/model/wallet_view_data.f.dart';
import 'package:ion/app/features/wallets/providers/transactions_visibility_cloud_backup.r.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:mocktail/mocktail.dart';

import '../data/fake_network_data.dart';
import '../data/fake_transaction_data.dart';
import '../data/fake_wallet.dart';
import '../data/fake_wallet_view_data.dart';

part 'sync_transactions_service_test_helpers.dart';

void main() {
  late List<Wallet> mockUserWallets;
  late MockNetworksRepository mockNetworksRepository;
  late MockCryptoWalletsRepository mockCryptoWalletsRepository;
  late MockTransactionLoader mockTransactionLoader;
  late MockTransferStatusUpdater mockTransferStatusUpdater;
  late MockWalletViewsService mockWalletViewsService;
  late MockTransactionsRepository mockTransactionsRepository;
  late MockTransactionsVisibilityCloudBackup mockTransactionsVisibilityCloudBackup;
  late SyncTransactionsService service;

  setUpAll(() {
    registerFallbackValue(
      FakeWallet.create(
        id: 'fallback',
        network: 'fallback',
        address: 'fallback',
        name: 'Fallback Wallet',
      ),
    );
  });

  setUp(() {
    mockUserWallets = FakeWallet.createStandardWallets();

    mockNetworksRepository = MockNetworksRepository();
    mockCryptoWalletsRepository = MockCryptoWalletsRepository();
    mockTransactionLoader = MockTransactionLoader();
    mockTransferStatusUpdater = MockTransferStatusUpdater();
    mockWalletViewsService = MockWalletViewsService();
    mockTransactionsRepository = MockTransactionsRepository();
    mockTransactionsVisibilityCloudBackup = MockTransactionsVisibilityCloudBackup();

    service = SyncTransactionsService(
      mockUserWallets,
      mockNetworksRepository,
      mockCryptoWalletsRepository,
      mockTransactionLoader,
      mockTransferStatusUpdater,
      mockWalletViewsService,
      mockTransactionsRepository,
      mockTransactionsVisibilityCloudBackup,
    );
  });

  void setupStandardMocks() {
    MockSetupHelper.setupNetworkMocks(mockNetworksRepository);
    MockSetupHelper.setupWalletViewsMocks(mockWalletViewsService);
    MockSetupHelper.setupCryptoWalletMocks(mockCryptoWalletsRepository);
    MockSetupHelper.setupTransactionLoaderMocks(mockTransactionLoader);
    MockSetupHelper.setupTransferStatusUpdaterMocks(mockTransferStatusUpdater);
    MockSetupHelper.setupTransactionsVisibilityCloudBackupMocks(
      mockTransactionsVisibilityCloudBackup,
    );
  }

  void setupBroadcastedTransfersMocks() {
    MockSetupHelper.setupNetworkMocks(
      mockNetworksRepository,
      ionHistorySupported: [true, false, true, true],
    );
    MockSetupHelper.setupWalletViewsMocks(
      mockWalletViewsService,
      walletIds: ['wallet1', 'wallet2'],
      symbolGroups: ['BTC', 'ETH'],
    );
    MockSetupHelper.setupTransactionLoaderMocks(mockTransactionLoader, returnValue: true);
    MockSetupHelper.setupTransferStatusUpdaterMocks(mockTransferStatusUpdater);
    MockSetupHelper.setupTransactionsVisibilityCloudBackupMocks(mockTransactionsVisibilityCloudBackup);
  }

  group('SyncTransactionsService', () {
    group('syncAll', () {
      test('syncs 3 wallets with ion history support and transaction loader returns false', () async {
        setupStandardMocks();

        when(
          () => mockCryptoWalletsRepository.isHistoryLoadedForWallet(
            walletId: any(named: 'walletId'),
          ),
        ).thenAnswer((_) async => false);

        when(
          () => mockTransactionLoader.load(
            wallet: any(named: 'wallet'),
            walletViewId: any(named: 'walletViewId'),
            isFullLoad: any(named: 'isFullLoad'),
          ),
        ).thenAnswer((_) async => false);

        when(
          () => mockTransferStatusUpdater.update(any()),
        ).thenAnswer((_) async {});

        when(
          () => mockCryptoWalletsRepository.save(
            wallet: any(named: 'wallet'),
            isHistoryLoaded: any(named: 'isHistoryLoaded'),
          ),
        ).thenAnswer((_) async {});

        await service.syncAll();

        verify(
          () => mockCryptoWalletsRepository.isHistoryLoadedForWallet(
            walletId: 'wallet1',
          ),
        ).called(1);
        verify(
          () => mockCryptoWalletsRepository.isHistoryLoadedForWallet(
            walletId: 'wallet2',
          ),
        ).called(1);
        verify(
          () => mockCryptoWalletsRepository.isHistoryLoadedForWallet(
            walletId: 'wallet3',
          ),
        ).called(1);

        verify(
          () => mockTransactionLoader.load(
            wallet: mockUserWallets[0],
            walletViewId: 'walletView1',
            isFullLoad: true,
          ),
        ).called(1);
        verify(
          () => mockTransactionLoader.load(
            wallet: mockUserWallets[1],
            walletViewId: 'walletView2',
            isFullLoad: true,
          ),
        ).called(1);
        verify(
          () => mockTransactionLoader.load(
            wallet: mockUserWallets[2],
            walletViewId: 'walletView3',
            isFullLoad: true,
          ),
        ).called(1);

        verify(
          () => mockTransferStatusUpdater.update(mockUserWallets[0]),
        ).called(1);
        verify(
          () => mockTransferStatusUpdater.update(mockUserWallets[1]),
        ).called(1);
        verify(
          () => mockTransferStatusUpdater.update(mockUserWallets[2]),
        ).called(1);

        verify(
          () => mockCryptoWalletsRepository.save(
            wallet: mockUserWallets[0],
            isHistoryLoaded: true,
          ),
        ).called(1);
        verify(
          () => mockCryptoWalletsRepository.save(
            wallet: mockUserWallets[1],
            isHistoryLoaded: true,
          ),
        ).called(1);
        verify(
          () => mockCryptoWalletsRepository.save(
            wallet: mockUserWallets[2],
            isHistoryLoaded: true,
          ),
        ).called(1);
      });

      test('skips sync when wallet network is not supported', () async {
        setupStandardMocks();

        when(() => mockNetworksRepository.getAllAsMap()).thenAnswer(
          (_) async => {
            'network1': FakeNetworkData.create(
              id: 'network1',
              isIonHistorySupported: true,
            ),
            // network2 is missing - not supported
          },
        );

        when(() => mockWalletViewsService.lastEmitted).thenReturn([
          FakeWalletViewData.create(
            id: 'walletView1',
            walletId: 'wallet1',
            symbolGroup: 'BTC',
          ),
          FakeWalletViewData.create(
            id: 'walletView2',
            walletId: 'wallet2',
            symbolGroup: 'ETH',
          ),
        ]);

        when(() => mockWalletViewsService.walletViews).thenAnswer(
          (_) => Stream.value([
            FakeWalletViewData.create(
              id: 'walletView1',
              walletId: 'wallet1',
              symbolGroup: 'BTC',
            ),
            FakeWalletViewData.create(
              id: 'walletView2',
              walletId: 'wallet2',
              symbolGroup: 'ETH',
            ),
          ]),
        );

        when(
          () => mockCryptoWalletsRepository.isHistoryLoadedForWallet(
            walletId: any(named: 'walletId'),
          ),
        ).thenAnswer((_) async => false);

        when(
          () => mockTransactionLoader.load(
            wallet: any(named: 'wallet'),
            walletViewId: any(named: 'walletViewId'),
            isFullLoad: any(named: 'isFullLoad'),
          ),
        ).thenAnswer((_) async => false);

        when(
          () => mockTransferStatusUpdater.update(any()),
        ).thenAnswer((_) async {});

        when(
          () => mockCryptoWalletsRepository.save(
            wallet: any(named: 'wallet'),
            isHistoryLoaded: any(named: 'isHistoryLoaded'),
          ),
        ).thenAnswer((_) async {});

        await service.syncAll();

        verify(
          () => mockCryptoWalletsRepository.isHistoryLoadedForWallet(
            walletId: 'wallet1',
          ),
        ).called(1);
        verify(
          () => mockCryptoWalletsRepository.isHistoryLoadedForWallet(
            walletId: 'wallet2',
          ),
        ).called(1);

        verifyNever(
          () => mockTransactionLoader.load(
            wallet: mockUserWallets[1],
            walletViewId: any(named: 'walletViewId'),
            isFullLoad: any(named: 'isFullLoad'),
          ),
        );

        verifyNever(
          () => mockTransferStatusUpdater.update(mockUserWallets[1]),
        );

        verifyNever(
          () => mockCryptoWalletsRepository.save(
            wallet: mockUserWallets[1],
            isHistoryLoaded: any(named: 'isHistoryLoaded'),
          ),
        );
      });

      test('skips sync when wallet is not connected to any wallet view', () async {
        setupStandardMocks();

        when(() => mockNetworksRepository.getAllAsMap()).thenAnswer(
          (_) async => {
            'network1': FakeNetworkData.create(
              id: 'network1',
              isIonHistorySupported: true,
            ),
            'network2': FakeNetworkData.create(
              id: 'network2',
              isIonHistorySupported: true,
            ),
          },
        );

        when(() => mockWalletViewsService.lastEmitted).thenReturn([
          FakeWalletViewData.create(
            id: 'walletView1',
            walletId: 'wallet1',
            symbolGroup: 'BTC',
          ),
          // walletView2 is missing - wallet2 not connected
        ]);

        when(() => mockWalletViewsService.walletViews).thenAnswer(
          (_) => Stream.value([
            FakeWalletViewData.create(
              id: 'walletView1',
              walletId: 'wallet1',
              symbolGroup: 'BTC',
            ),
            // walletView2 is missing - wallet2 not connected
          ]),
        );

        when(
          () => mockCryptoWalletsRepository.isHistoryLoadedForWallet(
            walletId: any(named: 'walletId'),
          ),
        ).thenAnswer((_) async => false);

        when(
          () => mockTransactionLoader.load(
            wallet: any(named: 'wallet'),
            walletViewId: any(named: 'walletViewId'),
            isFullLoad: any(named: 'isFullLoad'),
          ),
        ).thenAnswer((_) async => false);

        when(
          () => mockTransferStatusUpdater.update(any()),
        ).thenAnswer((_) async {});

        when(
          () => mockCryptoWalletsRepository.save(
            wallet: any(named: 'wallet'),
            isHistoryLoaded: any(named: 'isHistoryLoaded'),
          ),
        ).thenAnswer((_) async {});

        await service.syncAll();

        verify(
          () => mockCryptoWalletsRepository.isHistoryLoadedForWallet(
            walletId: 'wallet1',
          ),
        ).called(1);
        verify(
          () => mockCryptoWalletsRepository.isHistoryLoadedForWallet(
            walletId: 'wallet2',
          ),
        ).called(1);

        verify(
          () => mockTransactionLoader.load(
            wallet: mockUserWallets[0],
            walletViewId: 'walletView1',
            isFullLoad: true,
          ),
        ).called(1);

        verify(
          () => mockTransferStatusUpdater.update(mockUserWallets[0]),
        ).called(1);

        verify(
          () => mockCryptoWalletsRepository.save(
            wallet: mockUserWallets[0],
            isHistoryLoaded: true,
          ),
        ).called(1);

        verifyNever(
          () => mockTransactionLoader.load(
            wallet: mockUserWallets[1],
            walletViewId: any(named: 'walletViewId'),
            isFullLoad: any(named: 'isFullLoad'),
          ),
        );

        verifyNever(
          () => mockTransferStatusUpdater.update(mockUserWallets[1]),
        );

        verifyNever(
          () => mockCryptoWalletsRepository.save(
            wallet: mockUserWallets[1],
            isHistoryLoaded: any(named: 'isHistoryLoaded'),
          ),
        );
      });
    });

    group('syncBroadcastedTransfers', () {
      test('syncs only wallets with broadcasted transfers from user wallets', () async {
        setupBroadcastedTransfersMocks();

        final broadcastedTransfers = MockSetupHelper.createBroadcastedTransfersTestData();
        when(() => mockTransactionsRepository.getBroadcastedTransfers()).thenAnswer((_) async => broadcastedTransfers);

        when(
          () => mockTransactionLoader.load(
            wallet: any(named: 'wallet'),
            walletViewId: any(named: 'walletViewId'),
            isFullLoad: any(named: 'isFullLoad'),
          ),
        ).thenAnswer((_) async => true);

        when(
          () => mockTransferStatusUpdater.update(any()),
        ).thenAnswer((_) async {});

        await service.syncBroadcastedTransfers();

        verify(() => mockTransactionsRepository.getBroadcastedTransfers()).called(1);

        verify(
          () => mockTransactionLoader.load(
            wallet: mockUserWallets[0],
            walletViewId: 'walletView1',
            isFullLoad: false,
          ),
        ).called(1);

        verifyNever(
          () => mockTransactionLoader.load(
            wallet: mockUserWallets[1],
            walletViewId: any(named: 'walletViewId'),
            isFullLoad: any(named: 'isFullLoad'),
          ),
        );

        verify(
          () => mockTransferStatusUpdater.update(mockUserWallets[1]),
        ).called(1);

        verify(
          () => mockTransferStatusUpdater.update(mockUserWallets[0]),
        ).called(1);

        verifyNever(
          () => mockCryptoWalletsRepository.save(
            wallet: any(named: 'wallet'),
            isHistoryLoaded: any(named: 'isHistoryLoaded'),
          ),
        );
      });

      test('skips sync when no broadcasted transfers are found', () async {
        setupBroadcastedTransfersMocks();

        when(() => mockTransactionsRepository.getBroadcastedTransfers()).thenAnswer((_) async => []);

        await service.syncBroadcastedTransfers();

        verify(() => mockTransactionsRepository.getBroadcastedTransfers()).called(1);

        verifyNever(
          () => mockTransactionLoader.load(
            wallet: any(named: 'wallet'),
            walletViewId: any(named: 'walletViewId'),
            isFullLoad: any(named: 'isFullLoad'),
          ),
        );

        verifyNever(
          () => mockTransferStatusUpdater.update(any()),
        );

        verifyNever(
          () => mockCryptoWalletsRepository.save(
            wallet: any(named: 'wallet'),
            isHistoryLoaded: any(named: 'isHistoryLoaded'),
          ),
        );
      });
    });

    group('syncBroadcastedTransactionsForWallet', () {
      test('throws exception when wallet not found in user wallets', () async {
        expect(
          () => service.syncBroadcastedTransactionsForWallet('unknown_address'),
          throwsA(isA<WalletNotFoundException>()),
        );
      });

      test('skips sync when no in-progress transactions found for wallet', () async {
        setupStandardMocks();

        when(
          () => mockTransactionsRepository.getTransactions(
            statuses: any(named: 'statuses'),
            walletAddresses: any(named: 'walletAddresses'),
          ),
        ).thenAnswer((_) async => []);

        await service.syncBroadcastedTransactionsForWallet('address1');

        verify(
          () => mockTransactionsRepository.getTransactions(
            statuses: TransactionStatus.inProgressStatuses,
            walletAddresses: ['address1'],
          ),
        ).called(1);

        verifyNever(
          () => mockTransactionLoader.load(
            wallet: any(named: 'wallet'),
            walletViewId: any(named: 'walletViewId'),
            isFullLoad: any(named: 'isFullLoad'),
          ),
        );

        verifyNever(
          () => mockTransferStatusUpdater.update(any()),
        );

        verifyNever(
          () => mockCryptoWalletsRepository.save(
            wallet: any(named: 'wallet'),
            isHistoryLoaded: any(named: 'isHistoryLoaded'),
          ),
        );
      });

      test('syncs wallet when in-progress transactions found', () async {
        setupStandardMocks();

        final inProgressTransactions = [
          FakeTransactionData.create(
            txHash: 'tx1',
            network: 'network1',
            type: TransactionType.send,
            status: TransactionStatus.executing,
            senderWalletAddress: 'address1',
            receiverWalletAddress: 'other1',
          ),
          FakeTransactionData.create(
            txHash: 'tx2',
            network: 'network1',
            type: TransactionType.receive,
            status: TransactionStatus.pending,
            senderWalletAddress: 'other2',
            receiverWalletAddress: 'address1',
          ),
        ];

        when(
          () => mockTransactionsRepository.getTransactions(
            statuses: any(named: 'statuses'),
            walletAddresses: any(named: 'walletAddresses'),
          ),
        ).thenAnswer((_) async => inProgressTransactions);

        when(
          () => mockTransactionLoader.load(
            wallet: any(named: 'wallet'),
            walletViewId: any(named: 'walletViewId'),
            isFullLoad: any(named: 'isFullLoad'),
          ),
        ).thenAnswer((_) async => true);

        when(
          () => mockTransferStatusUpdater.update(any()),
        ).thenAnswer((_) async {});

        await service.syncBroadcastedTransactionsForWallet('address1');

        verify(
          () => mockTransactionsRepository.getTransactions(
            statuses: TransactionStatus.inProgressStatuses,
            walletAddresses: ['address1'],
          ),
        ).called(1);

        verify(
          () => mockTransactionLoader.load(
            wallet: mockUserWallets[0],
            walletViewId: 'walletView1',
            isFullLoad: false,
          ),
        ).called(1);

        verify(
          () => mockTransferStatusUpdater.update(mockUserWallets[0]),
        ).called(1);

        verifyNever(
          () => mockCryptoWalletsRepository.save(
            wallet: any(named: 'wallet'),
            isHistoryLoaded: any(named: 'isHistoryLoaded'),
          ),
        );
      });
    });

    group('syncCoinTransactions', () {
      test('skips sync when empty symbol group provided', () async {
        when(() => mockWalletViewsService.lastEmitted).thenReturn([]);
        when(() => mockWalletViewsService.walletViews).thenAnswer(
          (_) => Stream.value([]),
        );

        await service.syncCoinTransactions('');

        verifyNever(
          () => mockTransactionLoader.load(
            wallet: any(named: 'wallet'),
            walletViewId: any(named: 'walletViewId'),
            isFullLoad: any(named: 'isFullLoad'),
          ),
        );

        verifyNever(
          () => mockTransferStatusUpdater.update(any()),
        );
      });

      test('skips sync when no wallets found with the specified coin', () async {
        setupStandardMocks();

        when(() => mockWalletViewsService.lastEmitted).thenReturn([]);

        when(() => mockWalletViewsService.walletViews).thenAnswer(
          (_) => Stream.value([
            FakeWalletViewData.create(
              id: 'walletView1',
              walletId: 'wallet1',
              symbolGroup: 'BTC',
            ),
          ]),
        );

        await service.syncCoinTransactions('ETH');

        verify(() => mockWalletViewsService.walletViews).called(1);

        verifyNever(
          () => mockTransactionLoader.load(
            wallet: any(named: 'wallet'),
            walletViewId: any(named: 'walletViewId'),
            isFullLoad: any(named: 'isFullLoad'),
          ),
        );

        verifyNever(
          () => mockTransferStatusUpdater.update(any()),
        );
      });

      test('syncs wallets that have the specified coin', () async {
        when(() => mockNetworksRepository.getAllAsMap()).thenAnswer(
          (_) async => {
            'network1': FakeNetworkData.create(
              id: 'network1',
              isIonHistorySupported: true,
            ),
            'network2': FakeNetworkData.create(
              id: 'network2',
              isIonHistorySupported: true,
            ),
          },
        );

        when(() => mockWalletViewsService.lastEmitted).thenReturn([]);

        when(() => mockWalletViewsService.walletViews).thenAnswer(
          (_) => Stream.value([
            FakeWalletViewData.create(
              id: 'walletView1',
              walletId: 'wallet1',
              symbolGroup: 'BTC',
            ),
            FakeWalletViewData.create(
              id: 'walletView2',
              walletId: 'wallet2',
              symbolGroup: 'BTC',
              networkId: 'network2',
            ),
            FakeWalletViewData.create(
              id: 'walletView3',
              walletId: 'unknown_wallet',
              symbolGroup: 'BTC',
            ),
          ]),
        );

        when(
          () => mockTransactionLoader.load(
            wallet: any(named: 'wallet'),
            walletViewId: any(named: 'walletViewId'),
            isFullLoad: any(named: 'isFullLoad'),
          ),
        ).thenAnswer((_) async => false);

        when(
          () => mockTransferStatusUpdater.update(any()),
        ).thenAnswer((_) async {});

        await service.syncCoinTransactions('BTC');

        // 1 - inside _getWalletsWithCoin
        // 2 - for each connected wallet inside _syncWallet
        verify(() => mockWalletViewsService.walletViews).called(3);

        verify(
          () => mockTransactionLoader.load(
            wallet: mockUserWallets[0],
            walletViewId: 'walletView1',
            isFullLoad: false,
          ),
        ).called(1);

        verify(
          () => mockTransactionLoader.load(
            wallet: mockUserWallets[1],
            walletViewId: 'walletView2',
            isFullLoad: false,
          ),
        ).called(1);

        verify(
          () => mockTransferStatusUpdater.update(mockUserWallets[0]),
        ).called(1);

        verify(
          () => mockTransferStatusUpdater.update(mockUserWallets[1]),
        ).called(1);

        verifyNever(
          () => mockCryptoWalletsRepository.save(
            wallet: any(named: 'wallet'),
            isHistoryLoaded: any(named: 'isHistoryLoaded'),
          ),
        );
      });
    });
  });
}
