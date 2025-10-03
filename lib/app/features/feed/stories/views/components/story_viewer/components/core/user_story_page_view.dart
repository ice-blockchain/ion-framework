// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/features/feed/stories/providers/story_viewing_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/user_stories_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/viewed_stories_provider.r.dart';
import 'package:ion/app/features/feed/stories/views/components/story_viewer/components/core/hooks/use_story_viewer_story_preload.dart';
import 'package:ion/app/features/feed/stories/views/components/story_viewer/components/core/story_content.dart';
import 'package:ion/app/features/feed/stories/views/components/story_viewer/components/core/story_gesture_handler.dart';
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
        if (context.mounted) {
          ref.read(viewedStoriesProvider.notifier).markStoryAsViewed(currentStory);
        }
      },
      [currentStory.id],
    );

    final resetPrefetchTargets = useStoryViewerStoryPreload(
      ref: ref,
      sessionPubkey: pubkey,
      stories: stories,
      currentStoryIndex: currentIndex,
    );

    void handleUserExit(VoidCallback callback) {
      resetPrefetchTargets();
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
