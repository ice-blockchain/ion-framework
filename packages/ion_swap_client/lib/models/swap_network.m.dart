// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'swap_network.m.freezed.dart';
part 'swap_network.m.g.dart';

@freezed
class SwapNetwork with _$SwapNetwork {
  factory SwapNetwork({
    required String id,
    required String name,
  }) = _SwapNetwork;

  factory SwapNetwork.fromJson(Map<String, dynamic> json) => _$SwapNetworkFromJson(json);
}
