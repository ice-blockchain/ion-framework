// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/wallets/domain/transactions/transfer_exception_handlers/aptos_exception_handler.dart';
import 'package:ion/app/features/wallets/domain/transactions/transfer_exception_handlers/bitcoin_exception_handler.dart';
import 'package:ion/app/features/wallets/domain/transactions/transfer_exception_handlers/cardano_exception_handler.dart';
import 'package:ion/app/features/wallets/domain/transactions/transfer_exception_handlers/general_exception_handler.dart';
import 'package:ion/app/features/wallets/domain/transactions/transfer_exception_handlers/polkadot_exception_handler.dart';
import 'package:ion/app/features/wallets/domain/transactions/transfer_exception_handlers/solana_exception_handler.dart';
import 'package:ion/app/features/wallets/domain/transactions/transfer_exception_handlers/transfer_exception_handler.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';

class TransferExceptionFactory {
  static final Map<String, TransferExceptionHandler> _networkHandlers = {
    'Polkadot': PolkadotExceptionHandler(),
    'Westends': PolkadotExceptionHandler(), // Polkadot testnet
    'Cardano': CardanoExceptionHandler(),
    'CardanoPreprod': CardanoExceptionHandler(), // Cardano testnet
    'Bitcoin': BitcoinExceptionHandler(),
    'BitcoinSignet': BitcoinExceptionHandler(), // Bitcoin testnet
    'Aptos': AptosExceptionHandler(),
    'AptosTestnet': AptosExceptionHandler(), // Aptos testnet
    'Solana': SolanaExceptionHandler(),
    'SolanaDevnet': SolanaExceptionHandler(), // Solana testnet
  };

  static final GeneralExceptionHandler _generalHandler = GeneralExceptionHandler();

  static IONException create(String? reason, CoinData coin) {
    final generalException = _generalHandler.tryHandle(reason, coin);
    if (generalException != null) return generalException;

    final networkHandler = _networkHandlers[coin.network.id];
    if (networkHandler != null) {
      final networkException = networkHandler.tryHandle(reason, coin);
      if (networkException != null) return networkException;
    }

    return FailedToSendCryptoAssetsException(reason);
  }
}
