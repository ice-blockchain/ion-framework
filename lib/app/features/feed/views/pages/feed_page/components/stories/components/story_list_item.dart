// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/features/feed/stories/providers/feed_stories_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/viewed_stories_provider.r.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/components/story_item_content.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/components/story_item_follow_button.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/components/story_list_separator.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/hooks/use_preload_story_media.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/mock.dart';
import 'package:ion/app/features/user/model/user_preview_data.dart';
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
    final userPreviewData = ref.watch(
          userPreviewDataProvider(pubkey, network: false).select((value) {
            final entity = value.valueOrNull;
            if (entity != null) {
              ListCachedObjects.updateObject<UserPreviewEntity>(context, entity);
            }
            return entity;
          }),
        ) ??
        ListCachedObjects.maybeObjectOf<UserPreviewEntity>(context, pubkey);
    final userStory = ref.watch(feedStoriesByPubkeyProvider(pubkey, showOnlySelectedUser: true));
    final storyReference = userStory.firstOrNull?.toEventReference();

    final gradient = useRef(
      storyBorderGradients[Random().nextInt(storyBorderGradients.length)],
    );

    final firstStory = userStory.firstOrNull;

    usePreloadStoryMedia(
      ref,
      firstStory,
      sessionPubkey: pubkey,
    );

    if (userPreviewData == null || storyReference == null) {
      return const SizedBox.shrink();
    }

    final isViewed = ref.watch(
      viewedStoriesProvider.select(
        (viewedStories) => viewedStories?.contains(storyReference) ?? false,
      ),
    );

    return Padding(
      padding: EdgeInsetsDirectional.only(start: StoryListSeparator.width),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            StoryItemContent(
              pubkey: pubkey,
              name: userPreviewData.data.name,
              gradient: gradient.value,
              isViewed: isViewed,
              onTap: () => StoryViewerRoute(pubkey: pubkey).push<void>(context),
            ),
            PositionedDirectional(
              end: 0,
              bottom: 18.0.s,
              child: StoryItemFollowButton(
                pubkey: pubkey,
                username: userPreviewData.data.name,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
