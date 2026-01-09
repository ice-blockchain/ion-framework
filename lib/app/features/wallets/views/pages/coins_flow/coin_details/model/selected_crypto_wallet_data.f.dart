// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_identity_client/ion_identity.dart';

part 'selected_crypto_wallet_data.f.freezed.dart';

@freezed
class SelectedCryptoWalletData with _$SelectedCryptoWalletData {
  const factory SelectedCryptoWalletData({
    required List<Wallet> wallets, // all wallets with disconnected
    required List<Wallet> disconnectedWallets,
    Wallet? selectedWallet,
  }) = _SelectedCryptoWalletData;

  factory SelectedCryptoWalletData.empty() => const SelectedCryptoWalletData(
        wallets: [],
        disconnectedWallets: [],
      );
}
