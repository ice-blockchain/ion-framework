// SPDX-License-Identifier: ice License 1.0

// freezed class with the viewmodel whith 2 subclasses 1 with the SuggestCreationDetailsResponse and 1 for skipped check
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
