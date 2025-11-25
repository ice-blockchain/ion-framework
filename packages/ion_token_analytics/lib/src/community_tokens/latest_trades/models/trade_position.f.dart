// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/addresses.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/creator.f.dart';

part 'trade_position.f.freezed.dart';
part 'trade_position.f.g.dart';

abstract class TradePositionBase {
  CreatorBase? get holder;
  AddressesBase? get addresses;
  String? get createdAt;
  String? get type;
  double? get amount;
  double? get amountUSD;
  double? get balance;
  double? get balanceUSD;
}

@freezed
class TradePosition with _$TradePosition implements TradePositionBase {
  const factory TradePosition({
    required Creator holder,
    required Addresses addresses,
    required String createdAt,
    required String type, // "buy/sell"
    required double amount,
    required double amountUSD,
    required double balance,
    required double balanceUSD,
  }) = _TradePosition;

  factory TradePosition.fromJson(Map<String, dynamic> json) => _$TradePositionFromJson(json);
}

@Freezed(copyWith: false)
class TradePositionPatch with _$TradePositionPatch implements TradePositionBase {
  const factory TradePositionPatch({
    CreatorPatch? holder,
    AddressesPatch? addresses,
    String? createdAt,
    String? type,
    double? amount,
    double? amountUSD,
    double? balance,
    double? balanceUSD,
  }) = _TradePositionPatch;

  factory TradePositionPatch.fromJson(Map<String, dynamic> json) =>
      _$TradePositionPatchFromJson(json);
}
