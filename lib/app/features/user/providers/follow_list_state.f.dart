// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'follow_list_state.f.freezed.dart';

@freezed
class CurrentUserFollowListWithMetadataState with _$CurrentUserFollowListWithMetadataState {
  const factory CurrentUserFollowListWithMetadataState({
    @Default([]) List<String> pubkeys,
    @Default(true) bool hasMore,
  }) = _CurrentUserFollowListWithMetadataState;
}
