// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_identity_client/src/wallets/services/wallet_views/models/wallet_view_coin_data.f.dart';

part 'short_wallet_view.f.freezed.dart';
part 'short_wallet_view.f.g.dart';

@freezed
class ShortWalletView with _$ShortWalletView {
  const factory ShortWalletView({
    required String name,
    @JsonKey(defaultValue: []) required List<WalletViewCoinData> coins,
    required String createdAt,
    required String updatedAt,
    required String userId,
    required String id,
    @JsonKey(defaultValue: []) required List<String> symbolGroups,
  }) = _ShortWalletView;

  factory ShortWalletView.fromJson(Map<String, dynamic> json) => _$ShortWalletViewFromJson(json);
}
