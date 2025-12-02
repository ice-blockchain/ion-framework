// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_swap_client/models/lets_exchange_network.m.dart';

part 'lets_exchange_coin.m.freezed.dart';
part 'lets_exchange_coin.m.g.dart';

@freezed
class LetsExchangeCoin with _$LetsExchangeCoin {
  factory LetsExchangeCoin({
    required String code,
    required String name,
    @JsonKey(name: 'is_active') required int isActive,
    required List<LetsExchangeNetwork> networks,
  }) = _LetsExchangeCoin;

  factory LetsExchangeCoin.fromJson(Map<String, dynamic> json) => _$LetsExchangeCoinFromJson(json);
}

extension LetsExchangeCoinActiveCheck on LetsExchangeCoin {
  bool get isCoinActive => isActive == 1;
}
