// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/core/providers/ion_connect_media_url_fallback_provider.r.dart';
import 'package:ion/app/features/core/providers/video_player_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/stories/providers/story_image_loading_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';

void usePreloadStoryMedia(WidgetRef ref, ModifiablePostEntity? story) {
  final context = useContext();

  useOnInit(
    () {
      if (story == null) return;
      final media = story.data.primaryMedia;
      if (media == null) return;
      if (media.mediaType == MediaType.image) {
        final cacheManager = ref.read(storyImageCacheManagerProvider);
        final resolvedUrl = ref.read(iONConnectMediaUrlFallbackProvider)[media.url] ?? media.url;

        unawaited(
          () async {
            try {
              // getSingleFile downloads when needed and refreshes the disk cache.
              await cacheManager.getSingleFile(resolvedUrl);
              if (!context.mounted) return;

              final cacheKey = Uri.tryParse(resolvedUrl)?.path ?? resolvedUrl;
              final provider = CachedNetworkImageProvider(
                resolvedUrl,
                cacheManager: cacheManager,
                cacheKey: cacheKey,
              );

              await precacheImage(provider, context);
            } catch (_) {
              // fall back to regular loading path.
            }
          }(),
        );
      } else if (media.mediaType == MediaType.video) {
        ref.read(
          videoControllerProvider(
            VideoControllerParams(
              sourcePath: media.url,
              authorPubkey: story.masterPubkey,
            ),
          ),
        );
      }
    },
    [story?.id],
  );
}
