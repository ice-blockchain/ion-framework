// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'addresses.f.freezed.dart';
part 'addresses.f.g.dart';

@freezed
class Addresses with _$Addresses {
  const factory Addresses({required String blockchain, required String ionConnect}) = _Addresses;

  factory Addresses.fromJson(Map<String, dynamic> json) => _$AddressesFromJson(json);
}
