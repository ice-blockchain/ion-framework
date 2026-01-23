// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/core/providers/ion_connect_media_url_provider.r.dart';
import 'package:ion/app/features/core/providers/video_player_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/stories/providers/story_feed_prefetch_registry_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/story_image_loading_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/story_video_controller_provider.m.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/services/file_cache/ion_cache_manager.dart';
import 'package:ion/app/services/logger/logger.dart';

void usePreloadStoryMedia(
  WidgetRef ref,
  ModifiablePostEntity? story, {
  required String sessionPubkey,
}) {
  final context = useContext();
  final hasRegistered = useRef(false);
  final registeredStoryId = useRef<String?>(null);

  useOnInit(
    () {
      if (story == null) return;
      final storyId = story.id;
      if (!context.mounted) {
        return;
      }
      final feedRegistry = ref.read(storyFeedPrefetchRegistryProvider(sessionPubkey));
      if (feedRegistry.contains(storyId)) {
        return;
      }
      ref.read(storyFeedPrefetchRegistryProvider(sessionPubkey).notifier).add(storyId);
      hasRegistered.value = true;
      registeredStoryId.value = storyId;
      unawaited(
        preloadStoryMedia(
          ref: ref,
          context: context,
          story: story,
          sessionPubkey: sessionPubkey,
        ),
      );
    },
    [story?.id, sessionPubkey],
  );

  useEffect(
    () {
      if (story == null) return null;
      final storyId = story.id;
      return () {
        if (!hasRegistered.value || registeredStoryId.value != storyId || !context.mounted) {
          return;
        }
        ref.read(storyFeedPrefetchRegistryProvider(sessionPubkey).notifier).remove(storyId);
        hasRegistered.value = false;
        registeredStoryId.value = null;
      };
    },
    [story?.id, sessionPubkey],
  );
}

Future<void> preloadStoryMedia({
  required WidgetRef ref,
  required BuildContext context,
  required ModifiablePostEntity story,
  required String sessionPubkey,
}) async {
  final media = story.data.primaryMedia;
  if (media == null || !context.mounted) return;

  if (media.mediaType == MediaType.image) {
    final cacheManager = ref.read(storyImageCacheManagerProvider);

    Future<void> precacheResolved(String url) async {
      await cacheManager.getSingleFile(url);
      if (!context.mounted) return;

      final imageProvider = CachedNetworkImageProvider(
        url,
        cacheManager: cacheManager,
        cacheKey: IONCacheManager.getCacheKeyFromIonUrl(url),
      );

      await precacheImage(imageProvider, context);
    }

    var resolvedUrl = ref.read(ionConnectMediaUrlProvider(media.url));

    try {
      await precacheResolved(resolvedUrl);
    } catch (e, stackTrace) {
      Logger.error(
        e,
        stackTrace: stackTrace,
        message: 'Failed to precache story image: $resolvedUrl',
      );

      // Advance the media URL fallback chain (CDN -> original -> relay host -> ...)
      // and retry precache once.
      final didFallback = await ref
          .read(ionConnectMediaUrlProvider(media.url).notifier)
          .generateFallback(authorPubkey: story.masterPubkey);

      if (!didFallback || !context.mounted) return;

      resolvedUrl = ref.read(ionConnectMediaUrlProvider(media.url));

      try {
        await precacheResolved(resolvedUrl);
      } catch (e, stackTrace) {
        Logger.error(
          e,
          stackTrace: stackTrace,
          message: 'Failed to precache story image after fallback: $resolvedUrl',
        );
      }
    }
    return;
  }

  if (media.mediaType == MediaType.video) {
    final params = VideoControllerParams(
      sourcePath: media.url,
      authorPubkey: story.masterPubkey,
      uniqueId: story.id,
    );

    if (!context.mounted) return;
    await ref.read(
      storyVideoControllerProvider(
        StoryVideoControllerParams(
          storyId: story.id,
          sessionPubkey: sessionPubkey,
          baseParams: params,
        ),
      ).future,
    );
  }
}
