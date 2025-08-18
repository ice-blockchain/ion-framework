// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/providers/feed_posts_provider.r.dart';
import 'package:ion/app/features/feed/providers/feed_videos_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
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

  Iterable<IonConnectEntity> _filterEntitiesFromEventReference(
    Iterable<IonConnectEntity> entities,
    EventReference targetEventReference,
  ) {
    final entitiesList = entities.toList();
    final targetIndex = entitiesList.indexWhere(
      (entity) => entity.toEventReference() == targetEventReference,
    );
    
    if (targetIndex == -1) {
      return entities;
    }
    
    return entitiesList.skip(targetIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allEntities = ref.watch(feedVideosProvider.select((state) => state.items ?? {}));

    final entities = _filterEntitiesFromEventReference(allEntities, eventReference);

    final videoCount = entities
        .where(
          (entity) =>
              ref.read(isVideoPostProvider(entity)) || ref.read(isVideoRepostProvider(entity)),
        )
        .length;

    final state = ref.read(feedVideosProvider);
    print('🔥 [d3g] FeedVideosPage videoCount: $videoCount');
    if (videoCount < 3 && state.hasMore) {
      print('🔥 [d3g] FeedVideosPage fetchEntities');
      ref.read(feedVideosProvider.notifier).fetchEntities();
    }
    print('🔥 [d3g] initialMediaIndex: ${initialMediaIndex}');

    return VideosVerticalScrollPage(
      eventReference: eventReference,
      initialMediaIndex: initialMediaIndex,
      framedEventReference: framedEventReference,
      hasMore: state.hasMore,
      entities: entities,
      onLoadMore: () {
        print('🔥 [d3g] FeedVideosPage onLoadMore');
        ref.read(feedVideosProvider.notifier).fetchEntities();
      },
    );
  }
}
