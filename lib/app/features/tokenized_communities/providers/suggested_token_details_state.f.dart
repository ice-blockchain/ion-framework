// SPDX-License-Identifier: ice License 1.0

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
