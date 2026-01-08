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

  const Creator._();

  factory Creator.fromJson(Map<String, dynamic> json) => _$CreatorFromJson(json);

  @override
  bool get isXUser => addresses?.twitter != null;
}

abstract class CreatorBase {
  String? get name;
  String? get display;
  bool? get verified;
  String? get avatar;
  AddressesBase? get addresses;

  bool get isXUser;
}
