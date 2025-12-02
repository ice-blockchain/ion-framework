// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_swap_client/models/exolix_network.m.dart';

part 'exolix_coin.m.freezed.dart';
part 'exolix_coin.m.g.dart';

@freezed
class ExolixCoin with _$ExolixCoin {
  factory ExolixCoin({
    required String code,
    required String name,
    required List<ExolixNetwork> networks,
  }) = _ExolixCoin;

  factory ExolixCoin.fromJson(Map<String, dynamic> json) => _$ExolixCoinFromJson(json);
}
