// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/repository/transactions_repository.m.dart';
import 'package:ion/app/features/wallets/domain/transactions/external_hash_processor.r.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/sentry/sentry_service.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transaction_loader.r.g.dart';

@riverpod
Future<TransactionLoader> transactionLoader(Ref ref) async {
  return TransactionLoader(
    await ref.watch(transactionsRepositoryProvider.future),
    await ref.watch(externalHashProcessorProvider.future),
  );
}

/// [TransactionLoader] loads all available transactions for the wallet and saves them.
/// If transactions have been synced before, it does this page by page.
/// If there were no changes to the saved data when trying to save a new page
/// and all other transactions have already been loaded, stops sync.
class TransactionLoader {
  const TransactionLoader(
    this._transactionsRepository,
    this._externalHashProcessor,
  );

  final TransactionsRepository _transactionsRepository;
  final ExternalHashProcessor _externalHashProcessor;

  Future<bool> load({
    required Wallet wallet,
    required String walletViewId,
    required bool isFullLoad,
  }) async {
    String? nextPageToken = '';
    final transactions = <TransactionData>[];

    try {
      while (nextPageToken != null) {
        final result = await _transactionsRepository.loadTransactions(
          wallet.id,
          walletViewId: walletViewId,
          pageSize: isFullLoad ? 500 : null,
          pageToken: nextPageToken.isEmpty ? null : nextPageToken,
        );

        nextPageToken = result.nextPageToken;

        if (result.transactions.isNotEmpty) {
          var resultTransactions = result.transactions;

          if (resultTransactions.any((t) => t.externalHash != null)) {
            resultTransactions = await _externalHashProcessor.process(resultTransactions);
            await _transactionsRepository.remove(
              txHashes: resultTransactions.map((t) => t.externalHash).nonNulls,
            );
          }

          if (isFullLoad) {
            transactions.addAll(resultTransactions);
          } else {
            final updated = await _transactionsRepository.saveTransactions(resultTransactions);
            if (!updated || nextPageToken == null) return true;
          }
        }
      }

      if (isFullLoad && transactions.isNotEmpty) {
        await _transactionsRepository.saveTransactions(transactions);
      }

      return true;
    } catch (e, stack) {
      Logger.error(
        e,
        stackTrace: stack,
        message: 'Failed to ${isFullLoad ? "load all" : "sync"} transactions',
      );
      await SentryService.logException(
        e,
        stackTrace: stack,
        tag: 'load_transactions_failure',
      );
      return false;
    }
  }
}
