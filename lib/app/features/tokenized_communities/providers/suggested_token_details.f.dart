// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'suggested_token_details.f.freezed.dart';

@freezed
class SuggestedTokenDetails with _$SuggestedTokenDetails {
  const factory SuggestedTokenDetails({
    required String ticker,
    required String name,
    required String picture,
  }) = _SuggestedTokenDetails;
}
