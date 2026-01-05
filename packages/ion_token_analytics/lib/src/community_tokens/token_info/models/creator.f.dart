// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

part 'creator.f.freezed.dart';
part 'creator.f.g.dart';

@freezed
class Creator with _$Creator implements CreatorBase {
  const factory Creator({
    String? display,
    bool? verified,
    String? name,
    String? avatar,
    Addresses? addresses,
  }) = _Creator;

  factory Creator.fromJson(Map<String, dynamic> json) => _$CreatorFromJson(json);
}

abstract class CreatorBase {
  String? get name;
  String? get display;
  bool? get verified;
  String? get avatar;
  AddressesBase? get addresses;
}

@Freezed(copyWith: false)
class CreatorPatch with _$CreatorPatch implements CreatorBase {
  const factory CreatorPatch({
    String? name,
    String? display,
    bool? verified,
    String? avatar,
    AddressesPatch? addresses,
  }) = _CreatorPatch;

  factory CreatorPatch.fromJson(Map<String, dynamic> json) => _$CreatorPatchFromJson(json);
}
