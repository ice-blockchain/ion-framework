// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/stories/providers/feed_stories_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/viewed_stories_provider.r.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/components/story_item_content.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/components/story_list_separator.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/hooks/use_preload_story_media.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/mock.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class StoryListItem extends HookConsumerWidget {
  const StoryListItem({
    required this.pubkey,
    super.key,
  });

  final String pubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMetadata = ref.watch(cachedUserMetadataProvider(pubkey));
    final userStory = ref.watch(feedStoriesByPubkeyProvider(pubkey, showOnlySelectedUser: true));
    final storyReference = userStory.firstOrNull?.toEventReference();

    final gradient = useRef(storyBorderGradients[Random().nextInt(storyBorderGradients.length)]);

    usePreloadStoryMedia(ref, userStory.firstOrNull);

    if (userMetadata == null || storyReference == null) {
      return const SizedBox.shrink();
    }

    final isViewed = ref.watch(
      viewedStoriesProvider
          .select((viewedStories) => viewedStories?.contains(storyReference) ?? false),
    );

    return Padding(
      padding: EdgeInsetsDirectional.only(start: StoryListSeparator.width),
      child: Material(
        color: Colors.transparent,
        child: StoryItemContent(
          pubkey: pubkey,
          name: userMetadata.data.name,
          gradient: gradient.value,
          isViewed: isViewed,
          onTap: () => StoryViewerRoute(pubkey: pubkey).push<void>(context),
        ),
      ),
    );
  }
}
