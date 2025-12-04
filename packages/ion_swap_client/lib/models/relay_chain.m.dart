// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_swap_client/models/relay_currency.m.dart';

part 'relay_chain.m.freezed.dart';
part 'relay_chain.m.g.dart';

@freezed
class RelayChain with _$RelayChain {
  factory RelayChain({
    required String name,
    required String displayName,
    required int id,
    required bool disabled,
    required RelayCurrency currency,
  }) = _RelayChain;

  factory RelayChain.fromJson(Map<String, dynamic> json) => _$RelayChainFromJson(json);
}
