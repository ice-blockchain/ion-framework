// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'addresses.f.freezed.dart';
part 'addresses.f.g.dart';

@freezed
class Addresses with _$Addresses implements AddressesPatch {
  const factory Addresses({required String blockchain, required String ionConnect}) = _Addresses;

  factory Addresses.fromJson(Map<String, dynamic> json) => _$AddressesFromJson(json);
}

@Freezed(copyWith: false)
class AddressesPatch with _$AddressesPatch {
  const factory AddressesPatch({String? blockchain, String? ionConnect}) = _AddressesPatch;

  factory AddressesPatch.fromJson(Map<String, dynamic> json) => _$AddressesPatchFromJson(json);
}
