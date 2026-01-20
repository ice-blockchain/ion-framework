// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/wallets/data/database/dao/networks_dao.m.dart';
import 'package:ion/app/features/wallets/data/repository/swaps_repository.r.dart';
import 'package:ion/app/features/wallets/data/repository/transactions_repository.m.dart';
import 'package:ion/app/features/wallets/domain/transactions/failed_transfer_service.r.dart';
import 'package:ion/app/features/wallets/domain/transactions/periodic_transactions_sync_service.r.dart';
import 'package:ion/app/features/wallets/domain/transactions/sync_transactions_service.r.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/features/wallets/model/transaction_status.f.dart';
import 'package:ion/app/features/wallets/model/transaction_type.dart';
import 'package:mocktail/mocktail.dart';

import '../data/fake_transaction_data.dart';

class MockSyncTransactionsService extends Mock implements SyncTransactionsService {}

class MockTransactionsRepository extends Mock implements TransactionsRepository {}

class MockFailedTransferService extends Mock implements FailedTransferService {}

class MockSwapsRepository extends Mock implements SwapsRepository {}

class MockNetworksDao extends Mock implements NetworksDao {}

void main() {
  late MockSyncTransactionsService mockSyncTransactionsService;
  late MockTransactionsRepository mockTransactionsRepository;
  late MockFailedTransferService mockFailedTransferService;
  late MockSwapsRepository mockSwapsRepository;
  late MockNetworksDao mockNetworksDao;
  late PeriodicTransactionsSyncService service;

  setUpAll(() {
    registerFallbackValue(<String>[]);
    registerFallbackValue(<TransactionStatus>[]);
    registerFallbackValue(<String?>[]);
  });

  setUp(() {
    mockSyncTransactionsService = MockSyncTransactionsService();
    mockTransactionsRepository = MockTransactionsRepository();
    mockFailedTransferService = MockFailedTransferService();
    mockSwapsRepository = MockSwapsRepository();
    mockNetworksDao = MockNetworksDao();

    when(
      () => mockSwapsRepository.getSwaps(
        toTxHashes: any(named: 'toTxHashes'),
        fromTxHashes: any(named: 'fromTxHashes'),
        fromWalletAddresses: any(named: 'fromWalletAddresses'),
        toWalletAddresses: any(named: 'toWalletAddresses'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => []);

    service = PeriodicTransactionsSyncService(
      mockSyncTransactionsService,
      mockTransactionsRepository,
      mockFailedTransferService,
      mockSwapsRepository,
      mockNetworksDao,
      initialSyncDelay: const Duration(microseconds: 10),
    );
  });

  tearDown(() {
    service.stopWatching();
  });

  void setupWatchTransactionsMock(StreamController<List<TransactionData>> controller) {
    when(
      () => mockTransactionsRepository.watchTransactions(
        statuses: any(named: 'statuses'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) => controller.stream);
  }

  void setupStandardMocks() {
    when(
      () => mockTransactionsRepository.getTransactions(
        statuses: any(named: 'statuses'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => []);

    when(
      () => mockTransactionsRepository.getTransactions(
        walletAddresses: any(named: 'walletAddresses'),
        statuses: any(named: 'statuses'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => []);

    when(
      () => mockSyncTransactionsService.syncBroadcastedTransactionsForWallet(any()),
    ).thenAnswer((_) async {});
  }

  List<TransactionData> createTestTransactions() {
    return [
      FakeTransactionData.create(
        txHash: 'tx1',
        network: 'network_1',
        type: TransactionType.send,
        status: TransactionStatus.executing,
        senderWalletAddress: 'wallet1',
        receiverWalletAddress: 'other',
        networkTier: 1,
      ),
      FakeTransactionData.create(
        txHash: 'tx2',
        network: 'network_1',
        type: TransactionType.send,
        status: TransactionStatus.pending,
        senderWalletAddress: 'wallet1',
        receiverWalletAddress: 'other',
        networkTier: 1,
      ),
      FakeTransactionData.create(
        txHash: 'tx3',
        network: 'network_1',
        type: TransactionType.send,
        status: TransactionStatus.broadcasted,
        senderWalletAddress: 'wallet1',
        receiverWalletAddress: 'other',
        networkTier: 1,
      ),
    ];
  }

  group('PeriodicTransfersSyncService', () {
    group('service lifecycle', () {
      test('can start and stop watching', () {
        setupWatchTransactionsMock(StreamController());

        service
          ..startWatching()
          ..stopWatching();

        verify(
          () => mockTransactionsRepository.watchTransactions(
            statuses: TransactionStatus.inProgressStatuses,
            limit: 100,
          ),
        ).called(1);
      });

      test('does not start watching if already running', () {
        setupWatchTransactionsMock(StreamController());

        service
          ..startWatching()
          ..startWatching();

        verify(
          () => mockTransactionsRepository.watchTransactions(
            statuses: any(named: 'statuses'),
            limit: any(named: 'limit'),
          ),
        ).called(1);
      });
    });

    group('transaction filtering', () {
      test('should sync outgoing transactions in tier 1 networks', () {
        final tx = FakeTransactionData.create(
          txHash: 'tx1',
          network: 'network_1',
          type: TransactionType.send,
          status: TransactionStatus.executing,
          senderWalletAddress: 'wallet1',
          receiverWalletAddress: 'other',
          networkTier: 1,
        );

        final shouldSync = service.shouldSyncTransaction(tx);
        expect(shouldSync, isTrue);
      });

      test('should sync outgoing transactions in tier 2 networks', () {
        final tx = FakeTransactionData.create(
          txHash: 'tx1',
          network: 'network_2',
          type: TransactionType.send,
          status: TransactionStatus.executing,
          senderWalletAddress: 'wallet1',
          receiverWalletAddress: 'other',
          networkTier: 2,
        );

        final shouldSync = service.shouldSyncTransaction(tx);
        expect(shouldSync, isTrue);
      });

      test('should sync incoming transactions in tier 1 networks', () {
        final tx = FakeTransactionData.create(
          txHash: 'tx1',
          network: 'network_1',
          type: TransactionType.receive,
          status: TransactionStatus.executing,
          senderWalletAddress: 'other',
          receiverWalletAddress: 'wallet1',
          networkTier: 1,
        );

        final shouldSync = service.shouldSyncTransaction(tx);
        expect(shouldSync, isTrue);
      });

      test('should NOT sync incoming transactions in tier 2 networks', () {
        final tx = FakeTransactionData.create(
          txHash: 'tx1',
          network: 'network_2',
          type: TransactionType.receive,
          status: TransactionStatus.executing,
          senderWalletAddress: 'other',
          receiverWalletAddress: 'wallet1',
          networkTier: 2,
        );

        final shouldSync = service.shouldSyncTransaction(tx);
        expect(shouldSync, isFalse);
      });
    });

    group('successful sync flow behavior', () {
      test('triggers _startSyncing when stream emits transactions', () async {
        final streamController = StreamController<List<TransactionData>>();
        final testTransactions = createTestTransactions();

        setupWatchTransactionsMock(streamController);
        setupStandardMocks();

        when(
          () => mockTransactionsRepository.getTransactions(
            statuses: any(named: 'statuses'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => testTransactions);

        service.startWatching();
        streamController.add(testTransactions);

        await Future<void>.delayed(const Duration(microseconds: 50));

        verify(
          () => mockTransactionsRepository.getTransactions(
            statuses: TransactionStatus.inProgressStatuses,
            limit: 100,
          ),
        ).called(1);

        await streamController.close();
      });

      test('skips processing when stream emits empty transaction list', () async {
        final streamController = StreamController<List<TransactionData>>();

        setupWatchTransactionsMock(streamController);

        service.startWatching();
        streamController.add([]);

        await Future<void>.delayed(const Duration(microseconds: 50));

        verifyNever(
          () => mockTransactionsRepository.getTransactions(
            statuses: any(named: 'statuses'),
            limit: any(named: 'limit'),
          ),
        );

        await streamController.close();
      });

      test('handles service not running during stream processing', () async {
        final streamController = StreamController<List<TransactionData>>();
        final tx = FakeTransactionData.create(
          txHash: 'tx1',
          network: 'network_1',
          type: TransactionType.send,
          status: TransactionStatus.executing,
          senderWalletAddress: 'wallet1',
          receiverWalletAddress: 'other',
          networkTier: 1,
        );

        setupWatchTransactionsMock(streamController);

        service
          ..startWatching()
          ..stopWatching();
        streamController.add([tx]);

        await Future<void>.delayed(const Duration(microseconds: 50));

        verifyNever(
          () => mockTransactionsRepository.getTransactions(
            statuses: any(named: 'statuses'),
            limit: any(named: 'limit'),
          ),
        );

        await streamController.close();
      });

      test('executes wallet sync with pending transactions', () async {
        final streamController = StreamController<List<TransactionData>>();
        final pendingTx = FakeTransactionData.create(
          txHash: 'tx1',
          network: 'network_1',
          type: TransactionType.send,
          status: TransactionStatus.pending,
          senderWalletAddress: 'wallet1',
          receiverWalletAddress: 'other',
          networkTier: 1,
        );

        setupWatchTransactionsMock(streamController);

        when(
          () => mockTransactionsRepository.getTransactions(
            statuses: any(named: 'statuses'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => [pendingTx]);

        when(
          () => mockTransactionsRepository.getTransactions(
            walletAddresses: ['wallet1'],
            statuses: any(named: 'statuses'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => [pendingTx]);

        when(
          () => mockSyncTransactionsService.syncBroadcastedTransactionsForWallet('wallet1'),
        ).thenAnswer((_) async {});

        service.startWatching();
        streamController.add([pendingTx]);

        await Future<void>.delayed(const Duration(microseconds: 100));

        verify(
          () => mockSyncTransactionsService.syncBroadcastedTransactionsForWallet('wallet1'),
        ).called(1);

        verify(
          () => mockTransactionsRepository.getTransactions(
            walletAddresses: ['wallet1'],
            statuses: TransactionStatus.inProgressStatuses,
            limit: 100,
          ),
        ).called(2);

        await streamController.close();
      });
    });
  });
}
