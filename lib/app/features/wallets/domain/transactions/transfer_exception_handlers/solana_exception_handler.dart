// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/wallets/domain/transactions/transfer_exception_handlers/transfer_exception_handler.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';

class SolanaExceptionHandler implements TransferExceptionHandler {
  static const double _maxFee = 0.00002;
  static const double _rentExemptThreshold = 0.003; // upper bound

  @override
  IONException? tryHandle(
    String? reason,
    CoinData coin, {
    double? nativeTokenTotalBalance,
    double? nativeTokenTransferAmount,
  }) {
    if (!coin.network.isSolana) return null;

    if (reason != null) {
      final lower = reason.toLowerCase();
      final solanaErrorMatch = RegExp(r'solana error #(\d+)').firstMatch(lower);

      if (solanaErrorMatch != null) {
        final base64Match = RegExp("'([A-Za-z0-9+/=]+)'").firstMatch(reason);
        if (base64Match != null) {
          final decodedData = _decodeBase64(base64Match.group(1)!);
          final result = _handleSolanaError(
            solanaErrorMatch.group(1)!,
            decodedData,
            nativeTokenTotalBalance,
            nativeTokenTransferAmount,
          );
          if (result != null) return result;
        }
      }
    }

    return null;
  }

  String? _decodeBase64(String encoded) {
    try {
      final bytes = base64Decode(encoded);
      return utf8.decode(bytes);
    } catch (e) {
      return null;
    }
  }

  IONException? _handleSolanaError(
    String errorCode,
    String? decodedData,
    double? nativeTokenTotalBalance,
    double? nativeTokenTransferAmount,
  ) {
    if (decodedData == null) return null;

    final unitsMatch = RegExp(r'unitsConsumed=(\d+)').firstMatch(decodedData);
    if (unitsMatch != null) {
      final consumedUnits = int.parse(unitsMatch.group(1)!);

      if (consumedUnits < 500) {
        if (nativeTokenTotalBalance != null && nativeTokenTransferAmount != null) {
          final required = nativeTokenTransferAmount + _maxFee + _rentExemptThreshold;
          if (nativeTokenTotalBalance < required) {
            return SolanaInsufficientBalanceException();
          }
        }
        return SolanaInvalidRecipientException();
      }
    }

    return null;
  }
}
