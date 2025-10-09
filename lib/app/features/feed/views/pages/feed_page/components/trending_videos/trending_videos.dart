// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/components/section_header/section_header.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/trending_videos_overlay.dart';
import 'package:ion/app/features/feed/providers/feed_trending_videos_provider.r.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/trending_videos/components/trending_videos_list.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/trending_videos/components/trending_videos_list_skeleton.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/trending_videos/components/video_icon.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class TrendingVideos extends HookConsumerWidget {
  const TrendingVideos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const listOverlay = TrendingVideosOverlay.vertical;

    final (:items, :hasMore) = ref.watch(feedTrendingVideosProvider);

    final postItems = useMemoized(
      () {
        return items?.whereType<ModifiablePostEntity>().toList();
      },
      [items],
    );

    if (postItems == null) {
      return Column(
        children: [
          SizedBox(height: 10.0.s),
          const TrendingVideosListSkeleton(listOverlay: listOverlay),
          SizedBox(height: 18.0.s),
          const SectionSeparator(),
        ],
      );
    }

    if (postItems.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SectionHeader(
          onPress: () {
            final eventReference = postItems.first.toEventReference();
            TrendingVideosRoute(
              eventReference: eventReference.encode(),
            ).push<void>(context);
          },
          title: context.i18n.feed_trending_videos,
          leadingIcon: const VideosIcon(),
          leadingIconOffset: 8.0.s,
          trailingIconSize: 20.0.s,
        ),
        LoadMoreBuilder(
          slivers: [
            TrendingVideosList(
              videos: postItems,
              listOverlay: listOverlay,
            ),
          ],
          hasMore: hasMore,
          onLoadMore: () => _onLoadMore(ref),
          builder: (context, slivers) => SizedBox(
            height: listOverlay.itemSize.height,
            child: CustomScrollView(
              scrollDirection: Axis.horizontal,
              slivers: slivers,
            ),
          ),
        ),
        SizedBox(height: 18.0.s),
        const SectionSeparator(),
      ],
    );
  }

  Future<void> _onLoadMore(WidgetRef ref) async {
    await ref.read(feedTrendingVideosProvider.notifier).fetchEntities();
  }
}
