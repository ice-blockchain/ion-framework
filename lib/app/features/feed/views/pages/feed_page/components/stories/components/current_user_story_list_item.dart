// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/stories/data/models/stories_references.f.dart';
import 'package:ion/app/features/feed/stories/providers/current_user_feed_story_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/viewed_stories_provider.r.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/components/current_user_avatar_with_permission.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/components/plus_button_with_permission.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';

class CurrentUserStoryListItem extends HookConsumerWidget {
  const CurrentUserStoryListItem({
    required this.pubkey,
    required this.gradient,
    super.key,
  });

  final String pubkey;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserMetadata = ref.watch(currentUserMetadataProvider);
    final userStory = ref.watch(currentUserFeedStoryProvider);
    final storyReference = userStory?.story.toEventReference();
    final storiesReferences = StoriesReferences(
      storyReference != null ? [storyReference] : const <EventReference>[],
    );
    final viewedStories = ref.watch(viewedStoriesControllerProvider(storiesReferences));
    final hasStories = userStory != null;

    final allStoriesViewed = useMemoized(
      () => hasStories && (viewedStories == null || viewedStories.isNotEmpty),
      [userStory, viewedStories],
    );

    return currentUserMetadata.maybeWhen(
      data: (userMetadata) {
        if (userMetadata == null) return const SizedBox.shrink();

        return Material(
          color: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              CurrentUserAvatarWithPermission(
                pubkey: pubkey,
                hasStories: hasStories,
                gradient: hasStories ? gradient : null,
                isViewed: allStoriesViewed,
                imageUrl: userMetadata.data.avatarUrl,
              ),
              const PlusButtonWithPermission(),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
