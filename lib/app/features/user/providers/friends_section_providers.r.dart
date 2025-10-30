// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'friends_section_providers.r.g.dart';

const _friendsCountThreshold = 3;

@riverpod
bool hasEnoughFriends(Ref ref) {
  final followListState = ref.watch(currentUserFollowListProvider);
  final friendCount = followListState.value?.masterPubkeys.length;
  return (friendCount ?? 0) >= _friendsCountThreshold;
}

@riverpod
bool shouldShowFriendsList(Ref ref) {
  final hasEnoughFriends = ref.watch(hasEnoughFriendsProvider);
  final isAnyMetadataLoaded = ref.watch(isAnyFriendMetadataLoadedProvider);

  final result = hasEnoughFriends && isAnyMetadataLoaded;
  return result;
}

@riverpod
bool isAnyFriendMetadataLoaded(Ref ref) {
  final pubkeys = ref.watch(currentUserFollowListProvider).valueOrNull?.masterPubkeys ?? [];
  if (pubkeys.isEmpty) return false;

  // Approximate number of items that is enough to cover the viewport.
  for (final pk in pubkeys.take(4)) {
    final metadata = ref.watch(userPreviewDataProvider(pk));
    if (metadata.hasValue) {
      return true;
    }
  }

  return false;
}
