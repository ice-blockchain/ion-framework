// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/repository/transactions_repository.m.dart';
import 'package:ion/app/features/wallets/domain/transactions/external_hash_processor.r.dart';
import 'package:ion/app/features/wallets/domain/transactions/failed_transfer_service.r.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/features/wallets/model/transaction_status.f.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transfer_status_updater.r.g.dart';

@Riverpod(keepAlive: true)
Future<TransferStatusUpdater> transferStatusUpdater(Ref ref) async {
  final transactionsRepository = await ref.watch(transactionsRepositoryProvider.future);
  final failedTransferService = await ref.watch(failedTransferServiceProvider.future);
  final externalHashProcessor = await ref.watch(externalHashProcessorProvider.future);

  return TransferStatusUpdater(
    transactionsRepository,
    failedTransferService,
    externalHashProcessor,
  );
}

///
/// [TransferStatusUpdater] updates the status of transfers in the wallet with the broadcasted status.
///
class TransferStatusUpdater {
  const TransferStatusUpdater(
    this._transactionsRepository,
    this._failedTransferService,
    this._externalHashProcessor,
  );

  final TransactionsRepository _transactionsRepository;
  final FailedTransferService _failedTransferService;
  final ExternalHashProcessor _externalHashProcessor;

  Future<void> update(Wallet wallet) async {
    final broadcasted = await _transactionsRepository.getBroadcastedTransfers(
      walletAddress: wallet.address,
    );
    if (broadcasted.isEmpty) return;

    final updated = <TransactionData>[];
    final externalHashesToRemove = <String>[];
    String? nextPageToken = '';

    try {
      while (nextPageToken != null) {
        final result = await _transactionsRepository.loadTransfers(
          wallet.id,
          pageToken: nextPageToken.isEmpty ? null : nextPageToken,
        );
        nextPageToken = result.nextPageToken;

        final filtered =
            result.items.where((e) => e.txHash != null && e.requestBody is CoinTransferRequestBody);

        for (final transfer in filtered) {
          final matching = broadcasted
              .firstWhereOrNull((t) => t.txHash == transfer.txHash || t.id == transfer.id);
          if (matching != null) {
            final newStatus = TransactionStatus.fromJson(transfer.status);
            // Can be different from initial one in some blockchains
            final txHash = transfer.txHash ?? matching.txHash;

            // Create updated transaction with external hash if hashes differ
            final updatedTransaction = matching.copyWith(
              txHash: txHash,
              status: newStatus,
              dateConfirmed: transfer.dateConfirmed,
              externalHash: matching.txHash != txHash ? matching.txHash : null,
            );

            if (matching.txHash != txHash) {
              externalHashesToRemove.add(matching.txHash);
            }

            updated.add(updatedTransaction);
            broadcasted.remove(matching);
          }
        }

        if (broadcasted.isEmpty) break;
      }

      if (updated.isNotEmpty) {
        final transactionsToSave = updated.any((t) => t.externalHash != null)
            ? await _externalHashProcessor.process(updated)
            : updated;

        Logger.log(
            'TransferStatusUpdater.update: Saving ${transactionsToSave.length} updated transactions: '
            '${transactionsToSave.map((t) => '${t.txHash}(${t.status})').join(', ')}');
        await _transactionsRepository.saveTransactions(transactionsToSave);
        await _handleFailedTransfersDeletion(transactionsToSave);
      }

      if (externalHashesToRemove.isNotEmpty) {
        await _transactionsRepository.remove(txHashes: externalHashesToRemove);
      }
    } catch (e, stack) {
      Logger.error(
        e,
        stackTrace: stack,
        message: 'Failed to update transfers for wallet(${wallet.id})',
      );
    }
  }

  Future<void> _handleFailedTransfersDeletion(List<TransactionData> transactions) async {
    for (final transaction in transactions) {
      if (transaction.status == TransactionStatus.failed &&
          transaction.userPubkey != null &&
          transaction.eventId != null) {
        await _failedTransferService.markTransferAsFailed(transaction);
      }
    }
  }
}
