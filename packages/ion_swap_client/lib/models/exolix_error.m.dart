// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'exolix_error.m.freezed.dart';
part 'exolix_error.m.g.dart';

@freezed
class ExolixError with _$ExolixError {
  factory ExolixError({
    required num fromAmount,
    required num toAmount,
    required String message,
    required num minAmount,
  }) = _ExolixError;

  factory ExolixError.fromJson(Map<String, dynamic> json) =>
      _$ExolixErrorFromJson(json);
}
