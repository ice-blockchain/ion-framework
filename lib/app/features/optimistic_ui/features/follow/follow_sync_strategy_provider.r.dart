// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_sync_strategy.dart';
import 'package:ion/app/features/optimistic_ui/features/follow/follow_sync_strategy.dart';
import 'package:ion/app/features/optimistic_ui/features/follow/model/user_follow.f.dart';
import 'package:ion/app/features/user/model/follow_list.f.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/app/features/user/providers/followers_count_provider.r.dart';
import 'package:ion/app/features/user/providers/user_events_metadata_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'follow_sync_strategy_provider.r.g.dart';

@riverpod
SyncStrategy<UserFollow> followSyncStrategy(Ref ref) {
  final ionNotifier = ref.read(ionConnectNotifierProvider.notifier);

  return FollowSyncStrategy(
    sendFollow: (follow) async {
      final followList = await ref.read(currentUserFollowListProvider.future);
      if (followList == null) {
        throw FollowListNotFoundException();
      }
      final followees = Set<Followee>.from(followList.data.list);
      final currentUserPubkey = ref.read(currentPubkeySelectorProvider);

      // Remove current user from the list to prevent self follow error
      // TODO: delete it after the release
      if (follow.pubkey == currentUserPubkey) {
        return;
      }

      followees.add(Followee(pubkey: follow.pubkey));

      final updatedFollowList = followList.data.copyWith(list: followees.toList());
      final updatedFollowListEvent = await ionNotifier.sign(updatedFollowList);
      final userEventsMetadataBuilder = await ref.read(userEventsMetadataBuilderProvider.future);

      await Future.wait([
        ionNotifier.sendEvent(updatedFollowListEvent),
        ionNotifier.sendEvent(
          updatedFollowListEvent,
          actionSource: ActionSourceUser(follow.pubkey),
          metadataBuilders: [userEventsMetadataBuilder],
          cache: false,
        ),
      ]);
      ref.read(followersCountProvider(follow.pubkey).notifier).addOne();
    },
    deleteFollow: (follow) async {
      final followList = await ref.read(currentUserFollowListProvider.future);
      if (followList == null) {
        throw FollowListNotFoundException();
      }
      final followees = Set<Followee>.from(followList.data.list);
      final followee = followees.firstWhereOrNull((followee) => followee.pubkey == follow.pubkey);
      if (followee == null) {
        return;
      }

      if (followees.contains(followee)) {
        followees.remove(followee);
      } else {
        return;
      }

      final updatedFollowList = followList.data.copyWith(list: followees.toList());
      final updatedFollowListEvent = await ionNotifier.sign(updatedFollowList);
      final userEventsMetadataBuilder = await ref.read(userEventsMetadataBuilderProvider.future);

      await Future.wait([
        ionNotifier.sendEvent(updatedFollowListEvent),
        ionNotifier.sendEvent(
          updatedFollowListEvent,
          actionSource: ActionSourceUser(follow.pubkey),
          metadataBuilders: [userEventsMetadataBuilder],
          cache: false,
        ),
      ]);
    },
    removeFromCache: (pubkey) async {
      final followList = ref.read(currentUserSyncFollowListProvider);
      if (followList == null) {
        return;
      }
      final followees = Set<Followee>.from(followList.data.list);
      final followee = followees.firstWhereOrNull((followee) => followee.pubkey == pubkey);
      if (followee == null) {
        return;
      }

      followees.remove(followee);

      final updatedFollowList = followList.data.copyWith(list: followees.toList());
      final updatedFollowEntity = followList.copyWith(data: updatedFollowList);
      await ref.read(ionConnectCacheProvider.notifier).cache(updatedFollowEntity);
      ref.read(followersCountProvider(pubkey).notifier).removeOne();
    },
  );
}
