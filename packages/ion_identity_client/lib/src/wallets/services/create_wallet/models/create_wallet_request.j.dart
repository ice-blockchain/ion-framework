// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/src/core/types/types.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_wallet_request.j.g.dart';

@JsonSerializable()
class CreateWalletRequest {
  const CreateWalletRequest({
    required this.network,
    required this.name,
  });

  factory CreateWalletRequest.fromJson(JsonObject map) => _$CreateWalletRequestFromJson(map);

  final String network;
  final String name;

  JsonObject toJson() => _$CreateWalletRequestToJson(this);
}
