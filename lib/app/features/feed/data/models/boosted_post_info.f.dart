// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'boosted_post_info.f.freezed.dart';
part 'boosted_post_info.f.g.dart';

@freezed
class BoostPostData with _$BoostPostData {
  const factory BoostPostData({
    required double cost,
    required int durationDays,
    required DateTime purchasedAt,
  }) = _BoostPostData;

  const BoostPostData._();

  factory BoostPostData.fromJson(Map<String, dynamic> json) => _$BoostPostDataFromJson(json);
}
