// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/providers/replies_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/video/views/pages/videos_vertical_scroll_page.dart';

class ReplyListVideosPage extends HookConsumerWidget {
  const ReplyListVideosPage({
    required this.parentEventReference,
    required this.eventReference,
    this.initialMediaIndex = 0,
    this.framedEventReference,
    super.key,
  });

  final EventReference parentEventReference;
  final EventReference eventReference;
  final EventReference? framedEventReference;
  final int initialMediaIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(repliesProvider(parentEventReference));
    final entities = provider?.data.items ?? {};
    final hasMore = provider?.hasMore ?? false;
    
    return VideosVerticalScrollPage(
      eventReference: eventReference,
      initialMediaIndex: initialMediaIndex,
      framedEventReference: framedEventReference,
      entities: entities,
      onLoadMore: hasMore
          ? () => ref
              .read(repliesProvider(parentEventReference).notifier)
              .loadMore(parentEventReference)
          : null,
    );
  }
}
