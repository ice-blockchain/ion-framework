// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/feed/stories/providers/feed_stories_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/story_image_loading_provider.r.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/components/story_item_content.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/components/story_list.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/components/story_list_skeleton.dart';
import 'package:ion/app/hooks/use_on_init.dart';

class Stories extends HookConsumerWidget {
  const Stories({super.key});

  static double get height => StoryItemContent.height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (items: stories, :hasMore) = ref.watch(feedStoriesProvider);

    useOnInit(
      () async {
        if (stories != null && stories.isNotEmpty) {
          stories
              .map((userStory) => userStory.story.data.primaryMedia)
              .where((media) => media != null && media.mediaType == MediaType.image)
              .map((media) => media!.url)
              .forEach((url) async => ref.read(storyImageCacheManagerProvider).downloadFile(url));
        }
      },
      [stories],
    );

    return Column(
      children: [
        if (stories == null)
          const StoryListSkeleton()
        else
          LoadMoreBuilder(
            slivers: [
              StoryList(
                pubkeys: stories.map((story) => story.pubkey).toList(),
              ),
            ],
            hasMore: hasMore,
            onLoadMore: () => _onLoadMore(ref),
            loadingIndicatorContainerBuilder: (context, child) {
              return Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(end: ScreenSideOffset.defaultSmallMargin),
                  child: SizedBox(
                    height: StoryItemContent.width,
                    child: child,
                  ),
                ),
              );
            },
            builder: (context, slivers) {
              return SizedBox(
                height: StoryItemContent.height,
                child: CustomScrollView(
                  scrollDirection: Axis.horizontal,
                  slivers: slivers,
                ),
              );
            },
          ),
        SizedBox(height: 16.0.s),
        const SectionSeparator(),
      ],
    );
  }

  Future<void> _onLoadMore(WidgetRef ref) {
    return ref.read(feedStoriesProvider.notifier).fetchEntities();
  }
}
