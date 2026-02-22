// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'okx_fee_address.m.freezed.dart';
part 'okx_fee_address.m.g.dart';

@freezed
class OkxFeeAddress with _$OkxFeeAddress {
  factory OkxFeeAddress({
    required String avalanceAddress,
    required String arbitrumAddress,
    required String optimistAddress,
    required String polygonAddress,
    required String solAddress,
    required String baseAddress,
    required String tonAddress,
    required String tronAddress,
    required String ethAddress,
    required String bnbAddress,
  }) = _OkxFeeAddress;

  factory OkxFeeAddress.fromJson(Map<String, dynamic> json) => _$OkxFeeAddressFromJson(json);
}
