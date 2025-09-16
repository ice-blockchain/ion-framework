// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/progress_bar/centered_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/status_bar/status_bar_color_wrapper.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/stories/providers/story_index_keeper_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/story_pause_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/story_viewing_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/user_stories_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/viewed_stories_provider.r.dart';
import 'package:ion/app/features/feed/stories/views/components/story_unavailable.dart';
import 'package:ion/app/features/feed/stories/views/components/story_viewer/components/components.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/video/views/hooks/use_status_bar_color.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/hooks/use_route_presence.dart';

class StoryViewerPage extends HookConsumerWidget {
  const StoryViewerPage({
    required this.pubkey,
    this.initialStoryReference,
    this.showOnlySelectedUser = false,
    super.key,
  });

  final String pubkey;
  final EventReference? initialStoryReference;
  final bool showOnlySelectedUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useStatusBarColor();

    if (initialStoryReference != null) {
      final initialStoryEntity =
          ref.watch(ionConnectEntityProvider(eventReference: initialStoryReference!)).valueOrNull;

      if (initialStoryEntity == null) {
        return const CenteredLoadingIndicator();
      }

      final isInitialStoryDeleted =
          initialStoryEntity is ModifiablePostEntity && initialStoryEntity.isDeleted;

      if (isInitialStoryDeleted) {
        return StoryUnavailable(post: initialStoryEntity);
      }
    }

    final storyViewerState = ref.watch(
      userStoriesViewingNotifierProvider(pubkey, showOnlySelectedUser: showOnlySelectedUser),
    );
    final singleUserStoriesViewerState = ref.watch(
      singleUserStoryViewingControllerProvider(storyViewerState.currentUserPubkey),
    );
    final stories = ref
            .watch(userStoriesProvider(storyViewerState.currentStory?.masterPubkey ?? pubkey))
            ?.toList() ??
        [];
    final viewedStories = ref.watch(viewedStoriesProvider) ?? {};

    // Prefetch next user's stories when approaching the end of current user's stories
    final currentUserStoriesLeft =
        stories.length - singleUserStoriesViewerState.currentStoryIndex - 1;
    final nextUserPubkey = storyViewerState.nextUserPubkey;
    final shouldPrefetch = currentUserStoriesLeft < 10 && nextUserPubkey != null;

    if (shouldPrefetch) {
      ref.watch(userStoriesProvider(nextUserPubkey));
    }

    useOnInit(
      () {
        if (storyViewerState.userStories.isEmpty && context.mounted && context.canPop()) {
          context.pop();
        }
      },
      [storyViewerState.userStories.isEmpty],
    );

    useOnInit(
      () async {
        final firstNotViewedStoryIndex =
            stories.indexWhere((story) => !viewedStories.contains(story.toEventReference()));
        final initialStoryIndex = initialStoryReference != null
            ? stories.indexWhere((story) => story.toEventReference() == initialStoryReference)
            : null;
        final currentUserPubkey = storyViewerState.currentUserPubkey;
        final currentStoryIndex =
            ref.read(storyIndexKeeperProvider.notifier).getStoryIndex(currentUserPubkey);
        final moveToIndex = initialStoryIndex ??
            (firstNotViewedStoryIndex != -1 ? firstNotViewedStoryIndex : currentStoryIndex);
        if (moveToIndex != -1 && moveToIndex < stories.length) {
          ref
              .watch(
                singleUserStoryViewingControllerProvider(currentUserPubkey).notifier,
              )
              .moveToStoryIndex(moveToIndex);
        }
      },
      // Do not include [viewedStories] to dependencies intentionally.
      // Opening a story leads to marking it as viewed,
      // that triggers [viewedStories] update which would re-trigger [moveToStoryIndex].
      [stories.length, storyViewerState.currentUserPubkey],
    );

    useRoutePresence(
      onBecameInactive: () => ref.read(storyPauseControllerProvider.notifier).paused = true,
      onBecameActive: () => ref.read(storyPauseControllerProvider.notifier).paused = false,
    );

    final isPaused = ref.watch(storyPauseControllerProvider);

    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
        final media = MediaQuery.of(context);
        final fixedTop = MediaQuery.paddingOf(context).top;
        final size = MediaQuery.sizeOf(context);
        final footerHeight = 82.0.s;

        return StatusBarColorWrapper.light(
          child: MediaQuery(
            // Prevent story's content from shrinking on keyboard open
            data: media
                .removeViewInsets(removeBottom: true)
                .removeViewPadding(removeBottom: true, removeTop: true),
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  PositionedDirectional(
                    top: fixedTop,
                    width: size.width,
                    height: size.height - fixedTop - footerHeight,
                    child: StoriesSwiper(
                      pubkey: pubkey,
                      userStories: storyViewerState.userStories,
                      currentUserIndex: storyViewerState.currentUserIndex,
                      showOnlySelectedUser: showOnlySelectedUser,
                    ),
                  ),
                  PositionedDirectional(
                    start: 0,
                    end: 0,
                    bottom: 0,
                    height: footerHeight,
                    child: IgnorePointer(
                      ignoring: isKeyboardVisible,
                      child: AnimatedOpacity(
                        opacity: (isKeyboardVisible || isPaused) ? 0 : 1,
                        duration: const Duration(milliseconds: 150),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: 28.0.s),
                            StoryProgressBarContainer(
                              pubkey: pubkey,
                              showOnlySelectedUser: showOnlySelectedUser,
                            ),
                            ScreenBottomOffset(margin: 16.0.s),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
