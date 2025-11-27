// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'lets_exchange_info.m.freezed.dart';
part 'lets_exchange_info.m.g.dart';

@freezed
class LetsExchangeInfo with _$LetsExchangeInfo {
  factory LetsExchangeInfo({
    @JsonKey(name: 'rate_id') required String rateId,
  }) = _LetsExchangeInfo;

  factory LetsExchangeInfo.fromJson(Map<String, dynamic> json) => _$LetsExchangeInfoFromJson(json);
}
