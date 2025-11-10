// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'swap_chain_data.m.freezed.dart';
part 'swap_chain_data.m.g.dart';

@freezed
class SwapChainData with _$SwapChainData {
  factory SwapChainData({
    required int chainIndex,
    required String chainName,
    required String dexTokenApproveAddress,
  }) = _SwapChainData;

  factory SwapChainData.fromJson(Map<String, dynamic> json) => _$SwapChainDataFromJson(json);
}
