// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'selected_crypto_wallet_data.f.freezed.dart';

@freezed
class SelectedCryptoWalletData with _$SelectedCryptoWalletData {
  const factory SelectedCryptoWalletData({
    required List<String> wallets,
    String? selectedWallet,
  }) = _SelectedCryptoWalletData;

  factory SelectedCryptoWalletData.empty() => const SelectedCryptoWalletData(
        wallets: [],
      );
}
