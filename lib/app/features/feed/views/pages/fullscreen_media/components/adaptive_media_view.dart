// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/views/pages/fullscreen_media/components/media_content_handler.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/video/views/components/video_not_found.dart';

class AdaptiveMediaView extends HookConsumerWidget {
  const AdaptiveMediaView({
    required this.eventReference,
    required this.initialMediaIndex,
    this.framedEventReference,
    super.key,
  });

  final EventReference eventReference;
  final EventReference? framedEventReference;
  final int initialMediaIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entityAsync = ref.watch(ionConnectEntityProvider(eventReference: eventReference));

    return entityAsync.maybeWhen(
      data: (entity) {
        if (entity is ModifiablePostEntity) {
          if (entity.isDeleted) {
            return const VideoNotFound();
          }
          return MediaContentHandler(
            post: entity,
            eventReference: eventReference,
            initialMediaIndex: initialMediaIndex,
            framedEventReference: framedEventReference,
          );
        } else if (entity is ArticleEntity) {
          return MediaContentHandler(
            article: entity,
            eventReference: eventReference,
            initialMediaIndex: initialMediaIndex,
            framedEventReference: framedEventReference,
          );
        }
        return const SizedBox.shrink();
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
