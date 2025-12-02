// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'lets_exchange_network.m.freezed.dart';
part 'lets_exchange_network.m.g.dart';

@freezed
class LetsExchangeNetwork with _$LetsExchangeNetwork {
  factory LetsExchangeNetwork({
    required String code,
    required String name,
    @JsonKey(name: 'is_active') required int isActive,
    @JsonKey(name: 'contract_address') required String? contractAddress,
  }) = _LetsExchangeNetwork;

  factory LetsExchangeNetwork.fromJson(Map<String, dynamic> json) =>
      _$LetsExchangeNetworkFromJson(json);
}
