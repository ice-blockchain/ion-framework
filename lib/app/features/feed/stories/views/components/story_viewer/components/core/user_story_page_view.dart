// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/stories/providers/story_video_prefetch_targets_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/story_viewing_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/user_stories_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/viewed_stories_provider.r.dart';
import 'package:ion/app/features/feed/stories/views/components/story_viewer/components/core/story_content.dart';
import 'package:ion/app/features/feed/stories/views/components/story_viewer/components/core/story_gesture_handler.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/hooks/use_preload_story_media.dart';
import 'package:ion/app/hooks/use_on_init.dart';

class UserStoryPageView extends HookConsumerWidget {
  const UserStoryPageView({
    required this.isCurrentUser,
    required this.onNextUser,
    required this.onPreviousUser,
    required this.onClose,
    required this.pubkey,
    super.key,
  });

  final bool isCurrentUser;
  final VoidCallback onNextUser;
  final VoidCallback onPreviousUser;
  final VoidCallback onClose;
  final String pubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final singleUserStoriesViewingState = ref.watch(
      singleUserStoryViewingControllerProvider(pubkey),
    );
    final singleUserStoriesNotifier = ref.watch(
      singleUserStoryViewingControllerProvider(pubkey).notifier,
    );
    final stories = ref.watch(userStoriesProvider(pubkey))?.toList() ?? [];
    final currentIndex = singleUserStoriesViewingState.currentStoryIndex;

    if (stories.isEmpty) {
      return const Center(
        child: IONLoadingIndicator(),
      );
    }

    final currentStory = isCurrentUser ? stories[currentIndex] : stories.first;
    useOnInit(
      () {
        ref
            .read(viewedStoriesProvider.notifier)
            .markStoryAsViewed(currentStory);
      },
      [currentStory.id],
    );

    useEffect(
      () {
        final notifier =
            ref.read(storyVideoPrefetchTargetsProvider(pubkey).notifier);
        return () {
          Future.microtask(notifier.clear);
        };
      },
      [pubkey],
    );

    String? storyIdAt(int index) {
      if (index < 0 || index >= stories.length) {
        return null;
      }
      return stories[index].id;
    }

    final windowStories = <ModifiablePostEntity>[];
    for (var offset = -2; offset <= 2; offset++) {
      if (offset == 0) continue;
      final targetIndex = currentIndex + offset;
      if (targetIndex < 0 || targetIndex >= stories.length) continue;
      windowStories.add(stories[targetIndex]);
    }

    useOnInit(
      () {
        if (!context.mounted) return;

        final nextIds = windowStories.map((story) => story.id).toSet();
        final currentIds = ref.read(storyVideoPrefetchTargetsProvider(pubkey));
        if (setEquals(nextIds, currentIds)) {
          return;
        }

        ref
            .read(storyVideoPrefetchTargetsProvider(pubkey).notifier)
            .replaceWith(windowStories.map((story) => story.id));

        for (final story in windowStories) {
          unawaited(
            preloadStoryMedia(
              ref: ref,
              context: context,
              story: story,
              sessionPubkey: pubkey,
              keepAliveForSession: true,
            ),
          );
        }
      },
      [
        pubkey,
        currentIndex,
        stories.length,
        storyIdAt(currentIndex - 2),
        storyIdAt(currentIndex - 1),
        storyIdAt(currentIndex + 1),
        storyIdAt(currentIndex + 2),
      ],
    );

    void handleUserExit(VoidCallback callback) {
      ref.read(storyVideoPrefetchTargetsProvider(pubkey).notifier).clear();
      callback();
    }

    return KeyboardVisibilityProvider(
      child: StoryGestureHandler(
        key: storyGestureKeyFor(pubkey),
        viewerPubkey: pubkey,
        onTapLeft: () => singleUserStoriesNotifier.rewind(
          onRewoundAll: () => handleUserExit(onPreviousUser),
        ),
        onTapRight: () => singleUserStoriesNotifier.advance(
          storiesLength: stories.length,
          onSeenAll: () => handleUserExit(onNextUser),
        ),
        child: StoryContent(
          key: Key(currentStory.id),
          story: currentStory,
          viewerPubkey: pubkey,
          onNext: () => singleUserStoriesNotifier.advance(
            storiesLength: stories.length,
            onSeenAll: () => handleUserExit(onNextUser),
          ),
        ),
      ),
    );
  }
}
