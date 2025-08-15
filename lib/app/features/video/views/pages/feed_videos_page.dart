// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/providers/feed_posts_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/video/views/pages/videos_vertical_scroll_page.dart';

class FeedVideosPage extends HookConsumerWidget {
  const FeedVideosPage({
    required this.eventReference,
    this.initialMediaIndex = 0,
    this.framedEventReference,
    super.key,
  });

  final EventReference eventReference;
  final EventReference? framedEventReference;
  final int initialMediaIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entities = ref.watch(feedPostsProvider.select((state) => state.items ?? {}));

    final videoCount = entities
        .where(
          (entity) =>
              ref.read(isVideoPostProvider(entity)) || ref.read(isVideoRepostProvider(entity)),
        )
        .length;

    final state = ref.read(feedPostsProvider);
    if (videoCount < 3 && state.hasMore) {
      ref.read(feedPostsProvider.notifier).fetchEntitiesUntilVideo();
    }

    return VideosVerticalScrollPage(
      eventReference: eventReference,
      initialMediaIndex: initialMediaIndex,
      framedEventReference: framedEventReference,
      hasMore: state.hasMore,
      entities: entities,
      onLoadMore: () => ref.read(feedPostsProvider.notifier).fetchEntitiesUntilVideo(),
    );
  }
}
