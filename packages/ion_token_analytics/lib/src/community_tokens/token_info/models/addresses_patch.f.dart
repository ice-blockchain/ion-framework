// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/addresses.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/patch.dart';

part 'addresses_patch.f.freezed.dart';
part 'addresses_patch.f.g.dart';

@freezed
class AddressesPatch with _$AddressesPatch, Patch<Addresses> {
  const factory AddressesPatch({String? blockchain, String? ionConnect}) = _AddressesPatch;

  const AddressesPatch._();

  factory AddressesPatch.fromJson(Map<String, dynamic> json) => _$AddressesPatchFromJson(json);

  @override
  Addresses merge(Addresses original) {
    return original.copyWith(
      blockchain: blockchain ?? original.blockchain,
      ionConnect: ionConnect ?? original.ionConnect,
    );
  }
}
