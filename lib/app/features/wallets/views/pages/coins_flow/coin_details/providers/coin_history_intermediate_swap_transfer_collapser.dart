// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion/app/extensions/object.dart';
import 'package:ion/app/features/wallets/model/coin_transaction_data.f.dart';
import 'package:ion/app/features/wallets/model/transaction_crypto_asset.f.dart';
import 'package:ion/app/features/wallets/model/transaction_type.dart';

class CoinHistoryIntermediateSwapTransferCollapseResult {
  const CoinHistoryIntermediateSwapTransferCollapseResult({
    required this.transactions,
    required this.collapsedCount,
  });

  final List<CoinTransactionData> transactions;
  final int collapsedCount;
}

class CoinHistoryIntermediateSwapTransferCollapser {
  const CoinHistoryIntermediateSwapTransferCollapser();

  /// UX heuristic: hides intermediate same-asset transfers inside multi-step swap transactions
  /// when they net to zero in a single on-chain tx.
  CoinHistoryIntermediateSwapTransferCollapseResult collapse(
    List<CoinTransactionData> transactions,
  ) {
    if (transactions.length < 2) {
      return CoinHistoryIntermediateSwapTransferCollapseResult(
        transactions: transactions,
        collapsedCount: 0,
      );
    }

    final keysToHide = _findIntermediateTransferKeys(transactions);
    if (keysToHide.isEmpty) {
      return CoinHistoryIntermediateSwapTransferCollapseResult(
        transactions: transactions,
        collapsedCount: 0,
      );
    }

    final filtered = transactions
        .where(
          (tx) => !keysToHide.contains(_transactionRowKey(tx)),
        )
        .toList();

    final intermediateTransfersCount = transactions.length - filtered.length;
    return CoinHistoryIntermediateSwapTransferCollapseResult(
      transactions: filtered,
      collapsedCount: intermediateTransfersCount,
    );
  }

  Set<String> _findIntermediateTransferKeys(List<CoinTransactionData> transactions) {
    final grouped = groupBy(transactions, _groupKey);
    final keysToHide = grouped.values
        .where(_isZeroNetRoundTrip)
        .expand(
          (group) => group.map(_transactionRowKey),
        )
        .toSet();

    return keysToHide;
  }

  String _groupKey(CoinTransactionData tx) {
    final coinId = tx.origin.cryptoAsset.as<CoinTransactionAsset>()?.coin.id ?? '';
    return '${tx.origin.walletViewId}_${tx.network.id}_${tx.origin.txHash}_$coinId';
  }

  bool _isZeroNetRoundTrip(List<CoinTransactionData> group) {
    if (group.length < 2) return false;

    var hasReceive = false;
    var hasSend = false;
    var netRawAmount = BigInt.zero;

    for (final tx in group) {
      final signedAmount = _signedRawAmount(tx);
      if (signedAmount == null) return false;

      if (signedAmount.isNegative) {
        hasSend = true;
      } else if (signedAmount > BigInt.zero) {
        hasReceive = true;
      }

      netRawAmount += signedAmount;
    }

    return hasReceive && hasSend && netRawAmount == BigInt.zero;
  }

  BigInt? _signedRawAmount(CoinTransactionData tx) {
    final rawAmount = tx.origin.cryptoAsset.as<CoinTransactionAsset>()?.rawAmount;
    if (rawAmount == null) return null;

    final parsed = BigInt.tryParse(rawAmount);
    if (parsed == null) return null;

    if (tx.origin.type == TransactionType.receive) {
      return parsed;
    }
    if (tx.origin.type == TransactionType.send) {
      return -parsed;
    }
    return null;
  }

  String _transactionRowKey(CoinTransactionData tx) {
    final coinId = tx.origin.cryptoAsset.as<CoinTransactionAsset>()?.coin.id ?? '';
    return '${tx.origin.txHash}_${tx.origin.type.value}_${tx.origin.index}_$coinId';
  }
}
