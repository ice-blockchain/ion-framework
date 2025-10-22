// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/stories/data/models/story_viewer_state.f.dart';
import 'package:ion/app/features/feed/stories/providers/story_viewing_provider.r.dart';
import 'package:ion/app/features/feed/stories/views/components/story_viewer/components/core/core.dart';

const Key storiesSwiperKey = Key('stories_swiper');
const Duration _pageTransitionDuration = Duration(milliseconds: 100);

class StoriesSwiper extends HookConsumerWidget {
  const StoriesSwiper({
    required this.userStories,
    required this.currentUserIndex,
    required this.pubkey,
    required this.showOnlySelectedUser,
    Key? key,
  }) : super(key: key ?? storiesSwiperKey);

  final List<ModifiablePostEntity> userStories;
  final int currentUserIndex;
  final String pubkey;
  final bool showOnlySelectedUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPageController = usePageController(initialPage: currentUserIndex);
    final userStoriesViewingState = ref.watch(
      userStoriesViewingNotifierProvider(pubkey, showOnlySelectedUser: showOnlySelectedUser),
    );
    final userStoriesNotifier = ref.watch(userStoriesViewingNotifierProvider(pubkey).notifier);

    ref.listen<UserStoriesViewerState>(
      userStoriesViewingNotifierProvider(pubkey),
      (prev, next) {
        if (prev?.currentUserIndex != next.currentUserIndex && userPageController.hasClients) {
          userPageController.animateToPage(
            next.currentUserIndex,
            duration: _pageTransitionDuration,
            curve: Curves.easeInOut,
          );
        }
      },
    );

    return CubePageView.builder(
      controller: userPageController,
      itemCount: userStories.length,
      onPageChanged: userStoriesNotifier.moveTo,
      itemBuilder: (context, userIndex, pageNotifier) {
        final isCurrentUser = userIndex == currentUserIndex;
        final userPubkey = userStoriesViewingState.pubkeyAtIndex(userIndex);

        void closeViewer() {
          if (context.mounted) {
            context.pop();
          }
        }

        return CubeWidget(
          index: userIndex,
          pageNotifier: pageNotifier,
          child: userPubkey == null
              ? const SizedBox.shrink()
              : UserStoryPageView(
                  pubkey: userPubkey,
                  isCurrentUser: isCurrentUser,
                  onClose: closeViewer,
                  onNextUser: () {
                    if (userPageController.hasClients && userIndex < userStories.length - 1) {
                      userPageController.nextPage(
                        duration: _pageTransitionDuration,
                        curve: Curves.easeInOut,
                      );
                      userStoriesNotifier.advance(
                        onClose: () {
                          if (context.mounted) {
                            context.pop();
                          }
                        },
                      );
                    } else {
                      closeViewer();
                    }
                  },
                  onPreviousUser: () {
                    if (userPageController.hasClients && userIndex > 0) {
                      userPageController.previousPage(
                        duration: _pageTransitionDuration,
                        curve: Curves.easeInOut,
                      );
                      userStoriesNotifier.rewind(
                        onClose: () {
                          if (context.mounted) {
                            context.pop();
                          }
                        },
                      );
                    } else {
                      closeViewer();
                    }
                  },
                ),
        );
      },
    );
  }
}
