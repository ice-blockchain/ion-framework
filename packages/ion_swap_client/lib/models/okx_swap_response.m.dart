// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_swap_client/models/okx_swap_transaction.m.dart';

part 'okx_swap_response.m.freezed.dart';
part 'okx_swap_response.m.g.dart';

@freezed
class OkxSwapResponse with _$OkxSwapResponse {
  factory OkxSwapResponse({
    required OkxSwapTransaction tx,
  }) = _OkxSwapResponse;

  factory OkxSwapResponse.fromJson(Map<String, dynamic> json) =>
      _$OkxSwapResponseFromJson(json);
}
