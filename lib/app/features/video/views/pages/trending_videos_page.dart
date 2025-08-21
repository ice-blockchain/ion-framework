// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/data/models/feed_modifier.dart';
import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/feed/data/repository/following_feed_seen_events_repository.r.dart';
import 'package:ion/app/features/feed/providers/feed_trending_videos_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/video/views/pages/videos_vertical_scroll_page.dart';

class TrendingVideosPage extends HookConsumerWidget {
  const TrendingVideosPage({
    required this.eventReference,
    super.key,
  });

  final EventReference eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entities = ref.watch(feedTrendingVideosProvider.select((state) => state.items ?? {}));
    final hasMore = ref.watch(feedTrendingVideosProvider.select((state) => state.hasMore));
    return VideosVerticalScrollPage(
      eventReference: eventReference,
      entities: entities,
      onLoadMore: hasMore ? () => ref.read(feedTrendingVideosProvider.notifier).fetchEntities() : null,
      onVideoSeen: (IonConnectEntity? video) {
        if (video == null) {
          return;
        }

        final repo = ref.read(followingFeedSeenEventsRepositoryProvider);
        unawaited(
          repo.save(
            video,
            feedType: FeedType.video,
            feedModifier: FeedModifier.trending(),
          ),
        );
      },
    );
  }
}
