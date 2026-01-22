// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/model/coin_data.f.dart';

String resolvePaymentTokenAddress(CoinData token) {
  final contractAddress = token.contractAddress.trim();
  if (contractAddress.isNotEmpty) return contractAddress;
  if (token.native) return 'bnb';
  throw StateError('Payment token has empty contractAddress and is not native');
}
