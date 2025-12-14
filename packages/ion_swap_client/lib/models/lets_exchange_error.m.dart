// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'lets_exchange_error.m.freezed.dart';
part 'lets_exchange_error.m.g.dart';

@freezed
class LetsExchangeError with _$LetsExchangeError {
  factory LetsExchangeError({
    required bool success,
    required String error,
  }) = _LetsExchangeError;

  factory LetsExchangeError.fromJson(Map<String, dynamic> json) =>
      _$LetsExchangeErrorFromJson(json);
}
