// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart';
import 'package:ion/app/features/wallets/model/transaction_crypto_asset.f.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';

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
    if (swap.fromNetworkId.toLowerCase() != networkId.toLowerCase()) return false;
    if (tx.network.id.toLowerCase() != networkId.toLowerCase()) return false;
    if (tx.senderWalletAddress != swap.fromWalletAddress) return false;
    if (tx.receiverWalletAddress?.toLowerCase() != bridgeAddress.toLowerCase()) return false;

    final txDate = tx.dateConfirmed ?? tx.dateRequested;
    if (!isWithinFromTxTimeWindow(swap.createdAt, txDate)) return false;
    if (!isOutTxAmountMatch(swap.amount, tx)) return false;

    return true;
  }

  /// Returns true if [tx] is a to-tx (incoming) match for [swap].
  /// To-tx: user receives tokens FROM the bridge on the destination network.
  /// [crossChainFee] is the total fee deducted from toAmount (calculated by linker).
  bool isToTxMatch(SwapTransactions swap, TransactionData tx, {BigInt? crossChainFee}) {
    if (swap.toNetworkId.toLowerCase() != networkId.toLowerCase()) return false;
    if (tx.network.id.toLowerCase() != networkId.toLowerCase()) return false;
    if (tx.receiverWalletAddress != swap.toWalletAddress) return false;
    if (tx.senderWalletAddress?.toLowerCase() != bridgeAddress.toLowerCase()) return false;
    if (!isWithinTimeWindow(swap.createdAt, tx.dateConfirmed)) return false;
    if (!isInTxAmountMatch(swap.toAmount, tx, crossChainFee: crossChainFee)) return false;

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
    if (swapAmountValue == null || txAmountValue == null) return false;
    if (swapAmountValue == BigInt.zero) return false;

    return amountsEqual(swapAmountValue, txAmountValue);
  }

  /// Incoming tx amount should equal expected receive amount minus applicable fees.
  /// [crossChainFee] is the total cross-chain fee to deduct from expected amount.
  bool isInTxAmountMatch(
    String expectedReceiveAmount,
    TransactionData tx, {
    BigInt? crossChainFee,
  }) {
    final (expectedAmount, txAmountValue) = parseAmounts(expectedReceiveAmount, tx);
    if (expectedAmount == null || txAmountValue == null) return false;
    if (expectedAmount == BigInt.zero) return false;

    final fee = crossChainFee ?? BigInt.zero;
    final expectedAfterFee = expectedAmount - fee;
    return amountsEqual(expectedAfterFee, txAmountValue);
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
