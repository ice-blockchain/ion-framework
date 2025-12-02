// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'creator.f.freezed.dart';
part 'creator.f.g.dart';

@freezed
class Creator with _$Creator implements CreatorBase {
  const factory Creator({
    required String name,
    required String display,
    required bool verified,
    String? ionConnect,
    String? avatar,
  }) = _Creator;

  factory Creator.fromJson(Map<String, dynamic> json) => _$CreatorFromJson(json);
}

abstract class CreatorBase {
  String? get name;
  String? get display;
  bool? get verified;
  String? get avatar;
  String? get ionConnect;
}

@Freezed(copyWith: false)
class CreatorPatch with _$CreatorPatch implements CreatorBase {
  const factory CreatorPatch({
    String? name,
    String? display,
    bool? verified,
    String? avatar,
    String? ionConnect,
  }) = _CreatorPatch;

  factory CreatorPatch.fromJson(Map<String, dynamic> json) => _$CreatorPatchFromJson(json);
}
