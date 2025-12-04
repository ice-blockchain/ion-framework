// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'addresses.f.freezed.dart';
part 'addresses.f.g.dart';

@freezed
class Addresses with _$Addresses implements AddressesBase {
  const factory Addresses({
    required String? blockchain,
    required String? ionConnect,
    String? twitter,
  }) = _Addresses;

  factory Addresses.fromJson(Map<String, dynamic> json) => _$AddressesFromJson(json);
}

abstract class AddressesBase {
  String? get blockchain;
  String? get ionConnect;
  String? get twitter;
}

@Freezed(copyWith: false)
class AddressesPatch with _$AddressesPatch implements AddressesBase {
  const factory AddressesPatch({String? blockchain, String? ionConnect, String? twitter}) =
      _AddressesPatch;

  factory AddressesPatch.fromJson(Map<String, dynamic> json) => _$AddressesPatchFromJson(json);
}
