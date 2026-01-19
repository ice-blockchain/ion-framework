// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart';
import 'package:ion/app/features/wallets/model/transaction_crypto_asset.f.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/services/logger/logger.dart';

abstract class SwapTransactionIdentifier {
  String get networkId;

  String get bridgeAddress;

  Duration get matchingTimeWindow => const Duration(hours: 6);

  /// Time window to look back for first-leg transactions.
  /// First-leg tx is confirmed BEFORE the swap record is saved to DB.
  Duration get firstLegLookbackWindow => const Duration(minutes: 10);

  /// ION bridge fee constants (in nanotons, 1 ION = 1_000_000_000 nanotons).
  /// Reference: https://docs.ton.org/foundations/fees
  static const int ionMessageFee = 60960000; // 0.06096 ION
  static const int ionBridgeFee = 500000000; // 0.5 ION

  /// Tolerance for amount comparison (in nanotons).
  /// Allows for minor rounding differences.
  static const int amountTolerance = 1;

  /// Returns true if [tx] is a first-leg (outgoing) match for [swap].
  /// First-leg: user sends tokens TO the bridge on the source network.
  bool isFirstLegMatch(SwapTransaction swap, TransactionData tx) {
    Logger.log(
      'SwapTxIdentifier[$networkId]: Checking first-leg match for '
      'swap ${swap.swapId} and tx ${tx.txHash}',
    );

    // Note: Network IDs in the database use mixed case (e.g., "Ion", "Bsc")
    // while identifiers and tx.network.id may use different casing.
    // We compare case-insensitively to handle both.
    if (swap.fromNetworkId.toLowerCase() != networkId.toLowerCase()) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: First-leg mismatch - '
        'swap.fromNetworkId (${swap.fromNetworkId}) != networkId ($networkId)',
      );
      return false;
    }
    if (tx.network.id.toLowerCase() != networkId.toLowerCase()) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: First-leg mismatch - '
        'tx.network.id (${tx.network.id}) != networkId ($networkId)',
      );
      return false;
    }
    if (tx.senderWalletAddress != swap.fromWalletAddress) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: First-leg mismatch - '
        'tx.sender (${tx.senderWalletAddress}) != swap.fromWallet (${swap.fromWalletAddress})',
      );
      return false;
    }
    if (tx.receiverWalletAddress?.toLowerCase() != bridgeAddress.toLowerCase()) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: First-leg mismatch - '
        'tx.receiver (${tx.receiverWalletAddress}) != bridgeAddress ($bridgeAddress)',
      );
      return false;
    }

    final txDate = tx.dateConfirmed ?? tx.dateRequested;
    if (!isWithinFirstLegTimeWindow(swap.createdAt, txDate)) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: First-leg mismatch - '
        'tx outside time window (swap: ${swap.createdAt.toUtc()}, tx: ${txDate?.toUtc()})',
      );
      return false;
    }
    if (!isOutTxAmountMatch(swap.amount, tx)) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: First-leg mismatch - '
        'amount mismatch (swap: ${swap.amount})',
      );
      return false;
    }

    Logger.log(
      'SwapTxIdentifier[$networkId]: First-leg MATCH found! '
      'Swap ${swap.swapId} <- tx ${tx.txHash}',
    );
    return true;
  }

  /// Returns true if [tx] is a second-leg (incoming) match for [swap].
  /// Second-leg: user receives tokens FROM the bridge on the destination network.
  bool isSecondLegMatch(SwapTransaction swap, TransactionData tx) {
    Logger.log(
      'SwapTxIdentifier[$networkId]: Checking second-leg match for '
      'swap ${swap.swapId} and tx ${tx.txHash}',
    );

    // Note: Network IDs in the database use mixed case (e.g., "Ion", "Bsc")
    // while identifiers and tx.network.id may use different casing.
    // We compare case-insensitively to handle both.
    if (swap.toNetworkId.toLowerCase() != networkId.toLowerCase()) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: Second-leg mismatch - '
        'swap.toNetworkId (${swap.toNetworkId}) != networkId ($networkId)',
      );
      return false;
    }
    if (tx.network.id.toLowerCase() != networkId.toLowerCase()) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: Second-leg mismatch - '
        'tx.network.id (${tx.network.id}) != networkId ($networkId)',
      );
      return false;
    }
    if (tx.receiverWalletAddress != swap.toWalletAddress) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: Second-leg mismatch - '
        'tx.receiver (${tx.receiverWalletAddress}) != swap.toWallet (${swap.toWalletAddress})',
      );
      return false;
    }
    if (tx.senderWalletAddress?.toLowerCase() != bridgeAddress.toLowerCase()) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: Second-leg mismatch - '
        'tx.sender (${tx.senderWalletAddress}) != bridgeAddress ($bridgeAddress)',
      );
      return false;
    }
    if (!isWithinTimeWindow(swap.createdAt, tx.dateConfirmed)) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: Second-leg mismatch - '
        'tx outside time window (swap: ${swap.createdAt.toUtc()}, tx: ${tx.dateConfirmed?.toUtc()})',
      );
      return false;
    }
    if (!isInTxAmountMatch(swap.toAmount, tx)) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: Second-leg mismatch - '
        'amount mismatch (expected: ${swap.toAmount})',
      );
      return false;
    }

    Logger.log(
      'SwapTxIdentifier[$networkId]: Second-leg MATCH found! '
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

  bool isWithinFirstLegTimeWindow(DateTime swapCreatedAt, DateTime? txDate) {
    if (txDate == null) return true;

    final swapUtc = swapCreatedAt.toUtc();
    final txUtc = txDate.toUtc();

    final difference = txUtc.difference(swapUtc);
    return difference >= -firstLegLookbackWindow && difference <= matchingTimeWindow;
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
    if (swapAmountValue == 0) {
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
  /// Override in subclasses to apply network-specific fee deductions.
  bool isInTxAmountMatch(String expectedReceiveAmount, TransactionData tx) {
    final (expectedAmount, txAmountValue) = parseAmounts(expectedReceiveAmount, tx);
    if (expectedAmount == null || txAmountValue == null) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: InTxAmount - parse failed '
        '(expected: $expectedReceiveAmount, tx raw amount: null)',
      );
      return false;
    }
    if (expectedAmount == 0) {
      Logger.log(
        'SwapTxIdentifier[$networkId]: InTxAmount - expected amount is 0',
      );
      return false;
    }

    // Default: direct comparison (subclasses override with fee logic)
    final isMatch = amountsEqual(expectedAmount, txAmountValue);
    Logger.log(
      'SwapTxIdentifier[$networkId]: InTxAmount - '
      'expectedAmount: $expectedAmount, txAmount: $txAmountValue, '
      'match: $isMatch',
    );
    return isMatch;
  }

  /// Parses swap amount and transaction raw amount as integers (nanotons).
  (int?, int?) parseAmounts(String swapAmount, TransactionData tx) {
    final txRawAmount = switch (tx.cryptoAsset) {
      CoinTransactionAsset(:final rawAmount) => rawAmount,
      _ => null,
    };

    if (txRawAmount == null) return (null, null);

    final swapAmountValue = int.tryParse(swapAmount);
    final txAmountValue = int.tryParse(txRawAmount);

    return (swapAmountValue, txAmountValue);
  }

  /// Compares two amounts with a small tolerance for rounding differences.
  bool amountsEqual(int expected, int actual, {int tolerance = amountTolerance}) {
    return (expected - actual).abs() <= tolerance;
  }
}
