// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'follow_list_state.f.freezed.dart';

@freezed
class UserFollowListWithMetadataState with _$UserFollowListWithMetadataState {
  const factory UserFollowListWithMetadataState({
    required List<String> allPubkeys,
    required List<String> pubkeys,
    required bool hasMore,
  }) = _UserFollowListWithMetadataState;
}
