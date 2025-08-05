// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/optimistic_ui/core/optimistic_sync_strategy.dart';
import 'package:ion/app/features/optimistic_ui/features/follow/model/user_follow.f.dart';

/// Sync strategy for toggling follows using IonConnectNotifier.
class FollowSyncStrategy implements SyncStrategy<UserFollow> {
  FollowSyncStrategy({
    required this.sendFollow,
    required this.deleteFollow,
    required this.removeFromCache,
  });

  final Future<void> Function(UserFollow) sendFollow;
  final Future<void> Function(UserFollow) deleteFollow;
  final void Function(String) removeFromCache;

  @override
  Future<UserFollow> send(UserFollow previous, UserFollow optimistic) async {
    final toggledToFollow = optimistic.following && !previous.following;
    final toggledToUnfollow = !optimistic.following && previous.following;

    if (toggledToFollow) {
      await sendFollow(optimistic);
    } else if (toggledToUnfollow) {
      removeFromCache(optimistic.pubkey);
      await deleteFollow(optimistic);
    }

    return optimistic;
  }
}
