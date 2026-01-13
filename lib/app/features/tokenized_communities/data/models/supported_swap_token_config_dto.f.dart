// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'supported_swap_token_config_dto.f.freezed.dart';
part 'supported_swap_token_config_dto.f.g.dart';

@freezed
class SupportedSwapTokenConfigDto with _$SupportedSwapTokenConfigDto {
  const factory SupportedSwapTokenConfigDto({
    required String network,
    required String address,
  }) = _SupportedSwapTokenConfigDto;

  factory SupportedSwapTokenConfigDto.fromJson(Map<String, dynamic> json) =>
      _$SupportedSwapTokenConfigDtoFromJson(json);
}
