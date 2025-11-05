// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/trending_videos_overlay.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/trending_videos/components/trending_videos_list_item.dart';

class TrendingVideosList extends StatelessWidget {
  const TrendingVideosList({
    required this.videos,
    required this.listOverlay,
    super.key,
  });

  final List<ModifiablePostEntity> videos;

  final TrendingVideosOverlay listOverlay;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: ScreenSideOffset.defaultSmallMargin,
      ),
      sliver: SliverList.builder(
        itemCount: videos.length,
        itemBuilder: (BuildContext context, int index) => TrendingVideoListItem(
          key: ValueKey(videos[index].id),
          video: videos[index],
          itemSize: listOverlay.itemSize,
        ),
      ),
    );
  }
}
