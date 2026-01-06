// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/model/selected_crypto_wallet_data.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_crypto_wallet_notifier.r.g.dart';

@riverpod
class SelectedCryptoWalletNotifier extends _$SelectedCryptoWalletNotifier {
  static const List<String> _wallets = [
    '0x736ce4593eb7bc5ec1c640cff00a527c80928a0c',
    '0xa82dbf68fc2822d9d4f431753fded2c904539cea',
    '0xa82dbf68fc2822d9d4f431753fded2c904539cea',
    '0xa82dbf68fc2822d9d4f431753fded2c904539cea',
    '0xa82dbf68fc2822d9d4f431753fded2c904539cea',
  ];

  @override
  SelectedCryptoWalletData build() => SelectedCryptoWalletData(
        selectedWallet: _wallets.first,
        wallets: _wallets,
      );

  set selectedWallet(String wallet) => state = state.copyWith(selectedWallet: wallet);
}
