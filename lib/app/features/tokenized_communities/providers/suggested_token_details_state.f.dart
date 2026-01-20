// SPDX-License-Identifier: ice License 1.0

// freezed class with the viewmodel whith 2 subclasses 1 with the SuggestCreationDetailsResponse and 1 for skipped check
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/tokenized_communities/providers/suggested_token_details.f.dart';

part 'suggested_token_details_state.f.freezed.dart';

@freezed
class SuggestedTokenDetailsState with _$SuggestedTokenDetailsState {
  const factory SuggestedTokenDetailsState.suggested({
    SuggestedTokenDetails? suggestedDetails,
  }) = SuggestedTokenDetailsStateSuggested;
  const factory SuggestedTokenDetailsState.skipped() = SuggestedTokenDetailsStateSkipped;
}
