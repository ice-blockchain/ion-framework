// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_identity_client/ion_identity.dart';

part 'wallet_view.f.freezed.dart';
part 'wallet_view.f.g.dart';

typedef WalletViewResponse = ({WalletView walletView, String? nextPageToken});

@freezed
class WalletView with _$WalletView {
  const factory WalletView({
    required String id,
    required String name,
    @CoinInWalletListConverter() required List<CoinInWallet> coins,
    @JsonKey(defaultValue: {}) required Map<String, WalletViewAggregationItem> aggregation,
    @JsonKey(defaultValue: []) required List<String> symbolGroups,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String userId,
    List<WalletNft>? nfts,
  }) = _WalletView;

  factory WalletView.fromJson(Map<String, dynamic> json) => _$WalletViewFromJson(json);
}

class CoinInWalletListConverter implements JsonConverter<List<CoinInWallet>, List<dynamic>> {
  const CoinInWalletListConverter();

  @override
  List<CoinInWallet> fromJson(List<dynamic> json) {
    return json.map((e) {
      final json = e as Map<String, dynamic>;
      return CoinInWallet(
        walletId: json['walletId']?.toString(),
        coin: Coin.fromJson(json),
      );
    }).toList();
  }

  @override
  List<dynamic> toJson(List<CoinInWallet> object) {
    return object.map((coinWithWallet) {
      return {
        'walletId': coinWithWallet.walletId,
        ...coinWithWallet.toJson(),
      };
    }).toList();
  }
}
