// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/feed/reposts/models/post_repost.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_sync_strategy.dart';

class RepostSyncStrategy implements SyncStrategy<PostRepost> {
  RepostSyncStrategy({
    required this.createRepost,
    required this.deleteRepost,
    required this.invalidateCounterCache,
    required this.updateRepostCache,
  });

  final Future<EventReference> Function(EventReference) createRepost;
  final Future<void> Function(EventReference) deleteRepost;
  final void Function(EventReference) invalidateCounterCache;
  final void Function(EventReference ref, int delta) updateRepostCache;

  @override
  Future<PostRepost> send(PostRepost previous, PostRepost optimistic) async {
    final toggledToRepost = optimistic.repostedByMe && !previous.repostedByMe;
    final toggledToUnrepost = !optimistic.repostedByMe && previous.repostedByMe;

    if (toggledToRepost) {
      try {
        final createdRepostReference = await createRepost(optimistic.eventReference);
        final result = optimistic.copyWith(
          myRepostReference: createdRepostReference,
        );
        _increment(result);

        return result;
      } catch (e) {
        rethrow;
      }
    } else if (toggledToUnrepost && previous.myRepostReference != null) {
      try {
        await deleteRepost(previous.myRepostReference!);

        final result = optimistic.copyWith(
          myRepostReference: null,
        );
        _tryDecrement(result);

        return result;
      } catch (e) {
        // Special handling for EntityNotFoundException - the repost doesn't exist
        // This can happen if the repost was already deleted on another device
        // or if there was a sync issue
        if (e is EntityNotFoundException) {
          final result = optimistic.copyWith(
            myRepostReference: null,
          );
          _tryDecrement(result);

          return result;
        }

        rethrow;
      }
    }

    return optimistic;
  }

  void _increment(PostRepost result) {
    updateRepostCache(result.eventReference, 1);
  }

  void _tryDecrement(PostRepost result) {
    // Additional cache clearing if backend counter is 0
    // This can happen if multiple users unrepost simultaneously
    // Note: totalRepostsCount now returns minimum 1 if repostedByMe is true
    if (result.repostsCount == 0 && result.quotesCount == 0) {
      invalidateCounterCache(result.eventReference);
    } else {
      updateRepostCache(result.eventReference, -1);
    }
  }
}
