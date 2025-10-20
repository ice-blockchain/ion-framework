// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/wallets/domain/transactions/transfer_exception_handlers/transfer_exception_handler.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';

/// Handles Solana-specific transaction errors.
///
/// **Key Capability**: Decodes base64-encoded error data from Solana error messages
/// and identifies specific error conditions.
///
/// **"unitsConsumed=0" Error Causes**:
/// When Solana reports "unitsConsumed=0", it means the transaction failed before
/// any compute units were consumed during execution. This typically indicates:
///
/// 1. **Insufficient Lamports (SOL)**:
///    - Account doesn't have enough SOL for transaction fees
///    - Account doesn't meet minimum rent-exempt requirements
///    - Token account has insufficient balance for transfer
///
/// 2. **Pre-execution Validation Failures**:
///    - Invalid account data or missing accounts
///    - Account ownership validation failed
///    - Program instruction data validation failed
///
/// 3. **Account State Issues**:
///    - Associated token accounts don't exist
///    - Account not properly initialized
///    - Account frozen or closed
///
/// 4. **Permission/Authority Issues**:
///    - Missing required signatures
///    - Incorrect account authorities
///    - Program access denied
///
/// 5. **Transaction Structure Problems**:
///    - Invalid instruction data
///    - Missing required accounts in transaction
///    - Incorrect program IDs
///
/// **Sources**: Based on Solana Stack Exchange discussions and official documentation
/// about transaction simulation failures and compute unit consumption patterns.

class SolanaExceptionHandler implements TransferExceptionHandler {
  @override
  IONException? tryHandle(String? reason, CoinData coin) {
    if (!_isSolana(coin)) return null;

    if (reason != null) {
      final lower = reason.toLowerCase();
      final solanaErrorMatch = RegExp(r'solana error #(\d+)').firstMatch(lower);

      if (solanaErrorMatch != null) {
        final base64Match = RegExp(r"'([A-Za-z0-9+/=]+)'").firstMatch(reason);
        if (base64Match != null) {
          final decodedData = _decodeBase64(base64Match.group(1)!);
          final result = _handleSolanaError(solanaErrorMatch.group(1)!, decodedData);
          if (result != null) return result;
        }
      }

      if (lower.contains('insufficient') && lower.contains('balance')) {
        return InsufficientAmountException();
      }
    }

    return null;
  }

  bool _isSolana(CoinData coin) {
    final networkId = coin.network.id;
    return networkId == 'Solana' || networkId == 'SolanaDevnet';
  }

  String? _decodeBase64(String encoded) {
    try {
      final bytes = base64Decode(encoded);
      return utf8.decode(bytes);
    } catch (e) {
      return null;
    }
  }

  IONException? _handleSolanaError(String errorCode, String? decodedData) {
    // Handle the verified case: unitsConsumed=0 indicates transaction failed before execution
    // This typically means insufficient funds or pre-execution validation failure
    if (decodedData?.contains('unitsConsumed=0') ?? false) {
      return InsufficientAmountException();
    }

    // For all other cases, return null to let other handlers or generic error handling take over
    return null;
  }
}
