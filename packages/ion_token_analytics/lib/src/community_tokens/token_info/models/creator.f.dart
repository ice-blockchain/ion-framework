// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'creator.f.freezed.dart';
part 'creator.f.g.dart';

@freezed
class Creator with _$Creator {
  const factory Creator({
    required String name,
    required String display,
    required bool verified,
    required String avatar,
    required String ionConnect,
  }) = _Creator;

  factory Creator.fromJson(Map<String, dynamic> json) => _$CreatorFromJson(json);
}
