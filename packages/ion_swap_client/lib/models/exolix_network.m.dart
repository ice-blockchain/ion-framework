// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'exolix_network.m.freezed.dart';
part 'exolix_network.m.g.dart';

@freezed
class ExolixNetwork with _$ExolixNetwork {
  factory ExolixNetwork({
    required String network,
    required String name,
    required String shortName,
    required bool isDefault,
    required String? contract,
  }) = _ExolixNetwork;

  factory ExolixNetwork.fromJson(Map<String, dynamic> json) => _$ExolixNetworkFromJson(json);
}
