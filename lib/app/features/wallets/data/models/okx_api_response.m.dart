// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'okx_api_response.m.freezed.dart';
part 'okx_api_response.m.g.dart';

@Freezed(genericArgumentFactories: true)
class OkxApiResponse<T> with _$OkxApiResponse<T> {
  factory OkxApiResponse({
    required String code,
    @JsonKey(name: 'data') required T data,
  }) = _OkxApiResponse<T>;

  factory OkxApiResponse.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) => _$OkxApiResponseFromJson(
        json,
        fromJsonT,
      );
}
