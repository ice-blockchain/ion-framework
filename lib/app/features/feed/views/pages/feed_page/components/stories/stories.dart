// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/stories/providers/feed_stories_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/viewed_stories_provider.r.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/components/story_item_content.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/components/story_list.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/components/story_list_skeleton.dart';

class Stories extends HookConsumerWidget {
  const Stories({super.key});

  static double get height => StoryItemContent.height + 8.0.s + SectionSeparator.defaultHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (items: stories, :hasMore, :ready) = ref.watch(feedStoriesProvider);

    final viewedStoriesReferences = ref.watch(viewedStoriesProvider);

    final pubkeys = useMemoized(
      () {
        final storyReferences = stories.map((story) => story.toEventReference()).toSet();

        final unseenStories = storyReferences.difference(viewedStoriesReferences ?? {});
        return [...unseenStories, ...storyReferences.difference(unseenStories)]
            .map((storyReference) => storyReference.masterPubkey)
            .toSet();
      },
      [stories, viewedStoriesReferences],
    );

    return Column(
      children: [
        SizedBox(height: 8.0.s),
        if (!ready)
          const StoryListSkeleton()
        else
          LoadMoreBuilder(
            slivers: [
              StoryList(pubkeys: pubkeys),
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
        SizedBox(height: 8.0.s),
        const SectionSeparator(),
      ],
    );
  }

  Future<void> _onLoadMore(WidgetRef ref) {
    return ref.read(feedStoriesProvider.notifier).fetchEntities();
  }
}
