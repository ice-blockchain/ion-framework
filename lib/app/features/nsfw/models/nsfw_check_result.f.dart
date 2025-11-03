// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'nsfw_check_result.f.freezed.dart';

@freezed
class NsfwCheckResult with _$NsfwCheckResult {
  const factory NsfwCheckResult.success({required bool hasNsfw}) = NsfwSuccess;
  const factory NsfwCheckResult.failure({required Object error}) = NsfwFailure;
}
