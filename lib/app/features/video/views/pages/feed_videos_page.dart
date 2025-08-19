// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/providers/feed_videos_provider.r.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final video = ref.watch(ionConnectEntityWithCountersProvider(eventReference: eventReference));
    final entities = <IonConnectEntity>[
      if (video != null) video,
      ...ref.watch(feedVideosProvider.select((state) => state.items ?? {})),
    ];
    final hasMore = ref.watch(feedVideosProvider.select((state) => state.hasMore));
    return VideosVerticalScrollPage(
      eventReference: eventReference,
      initialMediaIndex: initialMediaIndex,
      framedEventReference: framedEventReference,
      entities: entities,
      hasMore: hasMore,
      onLoadMore: ref.read(feedVideosProvider.notifier).fetchEntities,
    );
  }
}
