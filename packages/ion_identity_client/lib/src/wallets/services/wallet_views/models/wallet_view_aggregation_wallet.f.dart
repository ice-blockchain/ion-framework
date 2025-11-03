// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_identity_client/src/wallets/services/get_wallet_assets/models/wallet_asset.f.dart';

part 'wallet_view_aggregation_wallet.f.freezed.dart';
part 'wallet_view_aggregation_wallet.f.g.dart';

@freezed
class WalletViewAggregationWallet with _$WalletViewAggregationWallet {
  const factory WalletViewAggregationWallet({
    required WalletAsset asset,
    required String walletId,
    required String network,
    String? coinId,
  }) = _WalletViewAggregationWallet;

  factory WalletViewAggregationWallet.fromJson(Map<String, dynamic> json) =>
      _$WalletViewAggregationWalletFromJson(json);
}
