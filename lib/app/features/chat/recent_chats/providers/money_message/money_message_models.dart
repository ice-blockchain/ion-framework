// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';

typedef MoneyDisplayData = ({
  String amount,
  String coin,
});

typedef MoneyMessageFallbackUiData = ({
  CoinData? coin,
  double amount,
  double equivalentUsd,
  String rawAmount,
  String networkId,
});

typedef SentMoneyMessageUiData = ({
  TransactionData? transactionData,
  NetworkData? network,
  CoinData? coin,
  double amount,
  double equivalentUsd,
});

typedef ResolvedMoneyAmountData = ({
  CoinData? coin,
  double? amount,
  String rawAmount,
});
