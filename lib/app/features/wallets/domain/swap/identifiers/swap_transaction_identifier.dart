// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart';
import 'package:ion/app/features/wallets/model/transaction_crypto_asset.f.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';

abstract class SwapTransactionIdentifier {
  String get networkId;

  String get bridgeAddress;

  Duration get matchingTimeWindow => const Duration(hours: 6);

  double get amountTolerancePercent => 5;

  /// Returns true if [tx] is a first-leg (outgoing) match for [swap].
  /// First-leg: user sends tokens TO the bridge on the source network.
  bool isFirstLegMatch(SwapTransaction swap, TransactionData tx) {
    if (swap.fromNetworkId != networkId) return false;
    if (tx.network.id != networkId) return false;
    if (tx.senderWalletAddress != swap.fromWalletAddress) return false;
    if (tx.receiverWalletAddress?.toLowerCase() != bridgeAddress.toLowerCase()) {
      return false;
    }
    if (!isWithinTimeWindow(swap.createdAt, tx.dateConfirmed)) return false;
    if (!isOutTxAmountMatch(swap.amount, tx)) return false;

    return true;
  }

  /// Returns true if [tx] is a second-leg (incoming) match for [swap].
  /// Second-leg: user receives tokens FROM the bridge on the destination network.
  bool isSecondLegMatch(SwapTransaction swap, TransactionData tx) {
    if (swap.toNetworkId != networkId) return false;
    if (tx.network.id != networkId) return false;
    if (tx.receiverWalletAddress != swap.toWalletAddress) return false;
    if (tx.senderWalletAddress?.toLowerCase() != bridgeAddress.toLowerCase()) {
      return false;
    }
    if (!isWithinTimeWindow(swap.createdAt, tx.dateConfirmed)) return false;
    if (!isInTxAmountMatch(swap.toAmount, tx)) return false;

    return true;
  }

  bool isWithinTimeWindow(DateTime swapCreatedAt, DateTime? txConfirmedAt) {
    if (txConfirmedAt == null) return true;

    final difference = txConfirmedAt.difference(swapCreatedAt);
    return difference >= Duration.zero && difference <= matchingTimeWindow;
  }

  /// Outgoing tx amount should be approximately equal to swap amount.
  /// Allows slight variance in either direction.
  bool isOutTxAmountMatch(String swapAmount, TransactionData tx) {
    final (expectedAmount, txAmountValue) = _parseAmounts(swapAmount, tx);
    if (expectedAmount == null || txAmountValue == null) return false;
    if (expectedAmount == 0) return false;

    final percentDifference =
        ((expectedAmount - txAmountValue).abs() / expectedAmount) * 100;

    return percentDifference <= amountTolerancePercent;
  }

  /// Incoming tx amount should be approximately equal to expected receive amount.
  /// Allows slight variance for minor fee differences.
  bool isInTxAmountMatch(String expectedReceiveAmount, TransactionData tx) {
    final (expectedAmount, txAmountValue) =
        _parseAmounts(expectedReceiveAmount, tx);
    if (expectedAmount == null || txAmountValue == null) return false;
    if (expectedAmount == 0) return false;

    final percentDifference =
        ((expectedAmount - txAmountValue).abs() / expectedAmount) * 100;

    return percentDifference <= amountTolerancePercent;
  }

  // TODO: Recheck during debug
  (double?, double?) _parseAmounts(String swapAmount, TransactionData tx) {
    final txRawAmount = switch (tx.cryptoAsset) {
      CoinTransactionAsset(:final rawAmount) => rawAmount,
      _ => null,
    };

    if (txRawAmount == null) return (null, null);

    final swapAmountValue = double.tryParse(swapAmount);
    final txAmountValue = double.tryParse(txRawAmount);

    return (swapAmountValue, txAmountValue);
  }
}
