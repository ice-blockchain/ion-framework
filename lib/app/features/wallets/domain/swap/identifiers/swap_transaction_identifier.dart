// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart';
import 'package:ion/app/features/wallets/model/transaction_crypto_asset.f.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/services/logger/logger.dart';

abstract class SwapTransactionIdentifier {
  String get networkId;

  String get bridgeAddress;

  Duration get matchingTimeWindow => const Duration(hours: 6);

  /// Time window to look back for from-tx transactions.
  /// From-tx tx is confirmed BEFORE the swap record is saved to DB.
  Duration get fromTxLookbackWindow => const Duration(minutes: 10);

  /// Tolerance for amount comparison (in smallest units).
  /// Allows for minor rounding differences.
  static const int amountTolerance = 1;

  /// Returns cross-chain fees for this network (in smallest units).
  /// Override in subclasses to provide network-specific fees.
  /// - isSource=true: fees when bridging OUT of this network
  /// - isSource=false: fees when bridging INTO this network
  BigInt getCrossChainFee({required bool isSource}) => BigInt.zero;

  /// Returns true if [tx] is a from-tx (outgoing) match for [swap].
  /// From-tx: user sends tokens TO the bridge on the source network.
  bool isFromTxMatch(SwapTransactions swap, TransactionData tx) {
    Logger.log(
      'SwapTxIdentifier[$networkId]: Checking from-tx match for '
      'swap ${swap.swapId} and tx ${tx.txHash}',
    );

    // Note: Network IDs in the database use mixed case (e.g., "Ion", "Bsc")
    // while identifiers and tx.network.id may use different casing.
    // We compare case-insensitively to handle both.
    if (swap.fromNetworkId.toLowerCase() != networkId.toLowerCase()) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: From-tx mismatch - '
        'swap.fromNetworkId (${swap.fromNetworkId}) != networkId ($networkId)',
      );
      return false;
    }
    if (tx.network.id.toLowerCase() != networkId.toLowerCase()) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: From-tx mismatch - '
        'tx.network.id (${tx.network.id}) != networkId ($networkId)',
      );
      return false;
    }
    if (tx.senderWalletAddress != swap.fromWalletAddress) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: From-tx mismatch - '
        'tx.sender (${tx.senderWalletAddress}) != swap.fromWallet (${swap.fromWalletAddress})',
      );
      return false;
    }
    if (tx.receiverWalletAddress?.toLowerCase() != bridgeAddress.toLowerCase()) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: From-tx mismatch - '
        'tx.receiver (${tx.receiverWalletAddress}) != bridgeAddress ($bridgeAddress)',
      );
      return false;
    }

    final txDate = tx.dateConfirmed ?? tx.dateRequested;
    if (!isWithinFromTxTimeWindow(swap.createdAt, txDate)) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: From-tx mismatch - '
        'tx outside time window (swap: ${swap.createdAt.toUtc()}, tx: ${txDate?.toUtc()})',
      );
      return false;
    }
    if (!isOutTxAmountMatch(swap.amount, tx)) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: From-tx mismatch - '
        'amount mismatch (swap: ${swap.amount})',
      );
      return false;
    }

    Logger.log(
      'SwapTxIdentifier[$networkId]: From-tx MATCH found! '
      'Swap ${swap.swapId} <- tx ${tx.txHash}',
    );
    return true;
  }

  /// Returns true if [tx] is a to-tx (incoming) match for [swap].
  /// To-tx: user receives tokens FROM the bridge on the destination network.
  /// [crossChainFee] is the total fee deducted from toAmount (calculated by linker).
  bool isToTxMatch(SwapTransactions swap, TransactionData tx, {BigInt? crossChainFee}) {
    Logger.log(
      'SwapTxIdentifier[$networkId]: Checking to-tx match for '
      'swap ${swap.swapId} and tx ${tx.txHash}',
    );

    // Note: Network IDs in the database use mixed case (e.g., "Ion", "Bsc")
    // while identifiers and tx.network.id may use different casing.
    // We compare case-insensitively to handle both.
    if (swap.toNetworkId.toLowerCase() != networkId.toLowerCase()) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: To-tx mismatch - '
        'swap.toNetworkId (${swap.toNetworkId}) != networkId ($networkId)',
      );
      return false;
    }
    if (tx.network.id.toLowerCase() != networkId.toLowerCase()) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: To-tx mismatch - '
        'tx.network.id (${tx.network.id}) != networkId ($networkId)',
      );
      return false;
    }
    if (tx.receiverWalletAddress != swap.toWalletAddress) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: To-tx mismatch - '
        'tx.receiver (${tx.receiverWalletAddress}) != swap.toWallet (${swap.toWalletAddress})',
      );
      return false;
    }
    if (tx.senderWalletAddress?.toLowerCase() != bridgeAddress.toLowerCase()) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: To-tx mismatch - '
        'tx.sender (${tx.senderWalletAddress}) != bridgeAddress ($bridgeAddress)',
      );
      return false;
    }
    if (!isWithinTimeWindow(swap.createdAt, tx.dateConfirmed)) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: To-tx mismatch - '
        'tx outside time window (swap: ${swap.createdAt.toUtc()}, tx: ${tx.dateConfirmed?.toUtc()})',
      );
      return false;
    }
    if (!isInTxAmountMatch(swap.toAmount, tx, crossChainFee: crossChainFee)) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: To-tx mismatch - '
        'amount mismatch (expected: ${swap.toAmount})',
      );
      return false;
    }

    Logger.log(
      'SwapTxIdentifier[$networkId]: To-tx MATCH found! '
      'Swap ${swap.swapId} -> tx ${tx.txHash}',
    );
    return true;
  }

  bool isWithinTimeWindow(DateTime swapCreatedAt, DateTime? txConfirmedAt) {
    if (txConfirmedAt == null) return true;

    final swapUtc = swapCreatedAt.toUtc();
    final txUtc = txConfirmedAt.toUtc();

    final difference = txUtc.difference(swapUtc);
    return difference >= Duration.zero && difference <= matchingTimeWindow;
  }

  bool isWithinFromTxTimeWindow(DateTime swapCreatedAt, DateTime? txDate) {
    if (txDate == null) return true;

    final swapUtc = swapCreatedAt.toUtc();
    final txUtc = txDate.toUtc();

    final difference = txUtc.difference(swapUtc);
    return difference >= -fromTxLookbackWindow && difference <= matchingTimeWindow;
  }

  /// Outgoing tx amount should equal swap amount minus applicable fees.
  /// Override in subclasses to apply network-specific fee deductions.
  bool isOutTxAmountMatch(String swapAmount, TransactionData tx) {
    final (swapAmountValue, txAmountValue) = parseAmounts(swapAmount, tx);
    if (swapAmountValue == null || txAmountValue == null) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: OutTxAmount - parse failed '
        '(swap: $swapAmount, tx raw amount: null)',
      );
      return false;
    }
    if (swapAmountValue == BigInt.zero) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: OutTxAmount - swap amount is 0',
      );
      return false;
    }

    // Default: direct comparison (subclasses override with fee logic)
    final isMatch = amountsEqual(swapAmountValue, txAmountValue);
    Logger.log(
      'SwapTxIdentifier[$networkId]: OutTxAmount - '
      'swapAmount: $swapAmountValue, txAmount: $txAmountValue, '
      'match: $isMatch',
    );
    return isMatch;
  }

  /// Incoming tx amount should equal expected receive amount minus applicable fees.
  /// [crossChainFee] is the total cross-chain fee to deduct from expected amount.
  bool isInTxAmountMatch(
    String expectedReceiveAmount,
    TransactionData tx, {
    BigInt? crossChainFee,
  }) {
    final (expectedAmount, txAmountValue) = parseAmounts(expectedReceiveAmount, tx);
    if (expectedAmount == null || txAmountValue == null) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: InTxAmount - parse failed '
        '(expected: $expectedReceiveAmount, tx raw amount: null)',
      );
      return false;
    }
    if (expectedAmount == BigInt.zero) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: InTxAmount - expected amount is 0',
      );
      return false;
    }

    final fee = crossChainFee ?? BigInt.zero;
    final expectedAfterFee = expectedAmount - fee;
    final isMatch = amountsEqual(expectedAfterFee, txAmountValue);
    Logger.log(
      'SwapTxIdentifier[$networkId]: InTxAmount - '
      'expectedAmount: $expectedAmount, fee: $fee, expectedAfterFee: $expectedAfterFee, '
      'txAmount: $txAmountValue, match: $isMatch',
    );
    return isMatch;
  }

  /// Parses swap amount and transaction raw amount as integers (nanotons).
  (BigInt?, BigInt?) parseAmounts(String swapAmount, TransactionData tx) {
    final txRawAmount = switch (tx.cryptoAsset) {
      CoinTransactionAsset(:final rawAmount) => rawAmount,
      _ => null,
    };

    if (txRawAmount == null) return (null, null);

    final swapAmountValue = BigInt.tryParse(swapAmount);
    final txAmountValue = BigInt.tryParse(txRawAmount);

    return (swapAmountValue, txAmountValue);
  }

  /// Compares two amounts with a small tolerance for rounding differences.
  bool amountsEqual(BigInt expected, BigInt actual, {int tolerance = amountTolerance}) {
    return (expected - actual).abs() <= BigInt.from(tolerance);
  }
}
