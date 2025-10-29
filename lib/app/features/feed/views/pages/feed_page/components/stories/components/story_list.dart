// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/features/feed/create_post/model/create_post_option.dart';
import 'package:ion/app/features/feed/create_post/providers/create_post_notifier.m.dart';
import 'package:ion/app/features/feed/stories/providers/feed_stories_provider.r.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/components/current_user_story_list_item.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/components/story_list_item.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/mock.dart';
import 'package:ion/app/features/user_block/providers/block_list_notifier.r.dart';

class StoryList extends ConsumerWidget {
  const StoryList({
    required this.pubkeys,
    super.key,
  });

  final Set<String> pubkeys;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserPubkey = ref.watch(currentPubkeySelectorProvider) ?? '';
    final blockedUsersPubkeys = ref
            .watch(currentUserBlockListNotifierProvider)
            .valueOrNull
            ?.map((block) => block.data.blockedMasterPubkeys)
            .expand((pubkey) => pubkey)
            .toList() ??
        [];

    final filteredPubkeys = pubkeys
        .where((pubkey) => pubkey != currentUserPubkey && !blockedUsersPubkeys.contains(pubkey))
        .toList();

    ref.listenSuccess(createPostNotifierProvider(CreatePostOption.story), (next) {
      ref.read(feedStoriesProvider.notifier).refresh();
    });

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: ScreenSideOffset.defaultSmallMargin),
      sliver: ListCachedObjectsWrapper(
        child: SliverList.builder(
          itemCount: filteredPubkeys.length + 1,
          itemBuilder: (_, index) {
            if (index == 0) {
              return CurrentUserStoryListItem(
                gradient: storyBorderGradients.first,
              );
            }

            final pubkey = filteredPubkeys[index - 1];
            return StoryListItem(
              key: Key('story_list_item_$pubkey'),
              pubkey: pubkey,
            );
          },
        ),
      ),
    );
  }
}
