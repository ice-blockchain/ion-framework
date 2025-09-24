// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/feed/stories/providers/stories_count_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/story_viewing_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/user_stories_provider.r.dart';
import 'package:ion/app/features/feed/stories/views/components/story_viewer/components/progress/progress.dart';

class StoryProgressBarContainer extends ConsumerWidget {
  const StoryProgressBarContainer({
    required this.pubkey,
    required this.showOnlySelectedUser,
    super.key,
  });

  final String pubkey;
  final bool showOnlySelectedUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserPubkey = ref.watch(
      userStoriesViewingNotifierProvider(
        pubkey,
        showOnlySelectedUser: showOnlySelectedUser,
      ).select((state) => state.currentUserPubkey),
    );
    final userStoriesNotifier = ref.watch(
      userStoriesViewingNotifierProvider(
        pubkey,
        showOnlySelectedUser: showOnlySelectedUser,
      ).notifier,
    );
    final singleUserStoriesViewingState =
        ref.watch(singleUserStoryViewingControllerProvider(currentUserPubkey));
    final singleUserStoriesNotifier = ref.watch(
      singleUserStoryViewingControllerProvider(currentUserPubkey).notifier,
    );
    final currentStoryIndex = singleUserStoriesViewingState.currentStoryIndex;
    final stories = ref.watch(userStoriesProvider(currentUserPubkey))?.toList() ?? [];
    final storiesCount = ref.watch(storiesCountProvider(currentUserPubkey)).valueOrNull;

    if (stories.isEmpty || storiesCount == null) {
      return const SizedBox();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0.s),
      child: Row(
        children: List.generate(storiesCount, (index) {
          final storyEntry = stories.elementAtOrNull(index);
          if (storyEntry == null) {
            return Expanded(
              child: StoryProgressSegment.placeholder(
                isCurrent: index == currentStoryIndex,
                isPreviousStory: index < currentStoryIndex,
                margin: index > 0 ? EdgeInsetsDirectional.only(start: 4.0.s) : null,
              ),
            );
          }

          final mediaType = storyEntry.data.primaryMedia?.mediaType ?? MediaType.unknown;
          final isVideo = mediaType == MediaType.video;
          return Expanded(
            child: StoryProgressTracker(
              key: ValueKey(storyEntry.id),
              post: storyEntry,
              isCurrent: index == currentStoryIndex,
              isPreviousStory: index < currentStoryIndex,
              onCompleted: isVideo
                  ? null
                  : () => singleUserStoriesNotifier.advance(
                        storiesLength: stories.length,
                        onSeenAll: () => userStoriesNotifier.advance(onClose: () => context.pop()),
                      ),
              sessionPubkey: currentUserPubkey,
              margin: index > 0 ? EdgeInsetsDirectional.only(start: 4.0.s) : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}
