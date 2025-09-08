// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:ion/app/features/wallets/data/repository/nfts_repository.r.dart';
import 'package:ion/app/features/wallets/data/repository/transactions_repository.m.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/transaction_crypto_asset.f.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/features/wallets/model/transaction_details.f.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stream_transform/stream_transform.dart';

part 'transaction_provider.r.g.dart';

@riverpod
class TransactionNotifier extends _$TransactionNotifier {
  StreamSubscription<List<TransactionData>>? _subscription;

  @override
  Future<TransactionDetails?> build({
    required String walletViewId,
    required String txHash,
  }) async {
    final repository = await ref.watch(transactionsRepositoryProvider.future);
    _subscription = repository
        .watchTransactions(
          externalHashes: [txHash],
          walletViewIds: [walletViewId],
          limit: 1,
        )
        .combineLatest(
          repository.watchTransactions(
            txHashes: [txHash],
            walletViewIds: [walletViewId],
            limit: 1,
          ),
          (externalHashData, directHashData) {
            if (externalHashData.isNotEmpty) return externalHashData;
            if (directHashData.isNotEmpty) return directHashData;
            return <TransactionData>[];
          },
        )
        .distinct((list1, list2) => const ListEquality<TransactionData>().equals(list1, list2))
        .listen(_handleTransactions);

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return null;
  }

  Future<void> _handleTransactions(List<TransactionData> transactions) async {
    try {
      if (transactions.isEmpty) {
        state = AsyncValue.error(Exception('No transaction was found'), StackTrace.current);
        return;
      }

      final transaction = transactions.first;

      // Handle NFT identifier resolution if needed
      final resolvedTransaction = await _resolveNftTransaction(transaction);
      final coinsGroup = _buildCoinsGroup(resolvedTransaction);

      final transactionDetails = TransactionDetails.fromTransactionData(
        resolvedTransaction,
        coinsGroup: coinsGroup,
      );

      state = AsyncValue.data(transactionDetails);
    } catch (error, _) {
      Logger.error('[TransactionNotifier] Error processing transaction: $error');
    }
  }

  CoinsGroup? _buildCoinsGroup(TransactionData transaction) {
    final coinAsset = transaction.cryptoAsset.mapOrNull(coin: (coin) => coin);
    if (coinAsset == null) {
      return null;
    }
    return CoinsGroup.fromCoin(coinAsset.coin);
  }

  Future<TransactionData> _resolveNftTransaction(TransactionData transaction) async {
    final nftIdentifierAsset = transaction.cryptoAsset.mapOrNull(nftIdentifier: (nftId) => nftId);
    if (nftIdentifierAsset == null) return transaction;

    final nftsRepository = ref.read(nftsRepositoryProvider);
    final nftData = await nftsRepository.getNftByIdentifier(nftIdentifierAsset.nftIdentifier);

    if (nftData != null) {
      return transaction.copyWith(cryptoAsset: TransactionCryptoAsset.nft(nft: nftData));
    }

    Logger.error(
      '[NFT Transaction Provider] NFT resolution failed - NFT data is null for identifier: '
      'Contract: ${nftIdentifierAsset.nftIdentifier.contract}, '
      'TokenId: ${nftIdentifierAsset.nftIdentifier.tokenId}',
    );

    // Return original transaction on failure
    return transaction;
  }
}
