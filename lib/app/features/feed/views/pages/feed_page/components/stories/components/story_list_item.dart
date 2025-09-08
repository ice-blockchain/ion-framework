// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/stories/providers/feed_stories_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/viewed_stories_provider.r.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/components/story_item_content.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/components/story_list_separator.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/hooks/use_preload_story_media.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/mock.dart';
import 'package:ion/app/features/optimistic_ui/features/follow/follow_provider.r.dart';
import 'package:ion/app/features/optimistic_ui/features/follow/hooks/use_follow_notification.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class StoryListItem extends HookConsumerWidget {
  const StoryListItem({
    required this.pubkey,
    super.key,
  });

  final String pubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMetadata = ref.watch(
      userMetadataSyncProvider(pubkey, network: false),
    );
    final userStory = ref.watch(feedStoriesByPubkeyProvider(pubkey, showOnlySelectedUser: true));
    final storyReference = userStory.firstOrNull?.toEventReference();

    final gradient = useRef(storyBorderGradients[Random().nextInt(storyBorderGradients.length)]);

    usePreloadStoryMedia(ref, userStory.firstOrNull);

    if (userMetadata == null || storyReference == null) {
      return const SizedBox.shrink();
    }

    final isFollowUser = ref.watch(
      isCurrentUserFollowingSelectorProvider(
        userMetadata.masterPubkey,
      ),
    );

    final isViewed = ref.watch(
      viewedStoriesProvider.select((viewedStories) => viewedStories?.contains(storyReference) ?? false),
    );

    ref.displayErrors(toggleFollowNotifierProvider);
    useFollowNotifications(
      context,
      ref,
      pubkey,
      userMetadata.data.name,
    );

    return Padding(
      padding: EdgeInsetsDirectional.only(start: StoryListSeparator.width),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            StoryItemContent(
              pubkey: pubkey,
              name: userMetadata.data.name,
              gradient: gradient.value,
              isViewed: isViewed,
              onTap: () => StoryViewerRoute(pubkey: pubkey).push<void>(context),
            ),
            Positioned(
              right: 0,
              bottom: 18.0.s,
              child: GestureDetector(
                onTap: () {
                  ref.read(toggleFollowNotifierProvider.notifier).toggle(pubkey);
                },
                child: Container(
                  width: 24.0.s,
                  height: 24.0.s,
                  decoration: BoxDecoration(
                    color: isFollowUser ? context.theme.appColors.success : context.theme.appColors.primaryAccent,
                    borderRadius: BorderRadius.circular(10.0.s),
                    border: Border.all(
                      width: 1.s,
                      color: context.theme.appColors.onPrimaryAccent,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isFollowUser
                        ? Assets.svg.iconSearchFollowers.icon(
                            color: context.theme.appColors.onPrimaryAccent,
                            size: 16.0.s,
                          )
                        : Assets.svg.iconLoginCreateacc.icon(
                            color: context.theme.appColors.onPrimaryAccent,
                            size: 16.0.s,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
