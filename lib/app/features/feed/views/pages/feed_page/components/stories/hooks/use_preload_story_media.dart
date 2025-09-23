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
import 'package:ion/app/features/feed/stories/providers/story_video_controller_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';

Future<void> _preloadStoryMedia({
  required WidgetRef ref,
  required BuildContext context,
  required ModifiablePostEntity story,
  String? sessionPubkey,
  bool keepAliveForSession = false,
}) async {
  final media = story.data.primaryMedia;
  if (media == null) return;

  if (media.mediaType == MediaType.image) {
    final cacheManager = ref.read(storyImageCacheManagerProvider);
    final resolvedUrl = ref.read(iONConnectMediaUrlFallbackProvider)[media.url] ?? media.url;

    try {
      await cacheManager.getSingleFile(resolvedUrl);
      if (!context.mounted) return;

      final cacheKey = Uri.tryParse(resolvedUrl)?.path ?? resolvedUrl;
      final imageProvider = CachedNetworkImageProvider(
        resolvedUrl,
        cacheManager: cacheManager,
        cacheKey: cacheKey,
      );

      await precacheImage(imageProvider, context);
    } catch (_) {
      // Fall back to the standard loading path when prefetch fails.
    }
    return;
  }

  if (media.mediaType == MediaType.video) {
    final params = VideoControllerParams(
      sourcePath: media.url,
      authorPubkey: story.masterPubkey,
      uniqueId: story.id,
    );

    final session = sessionPubkey;

    if (keepAliveForSession && session != null) {
      ref.read(
        storyVideoControllerProvider(
          StoryVideoControllerParams(
            storyId: story.id,
            sessionPubkey: session,
            baseParams: params,
          ),
        ),
      );
    } else {
      ref.read(
        videoControllerProvider(params),
      );
    }
  }
}

void usePreloadStoryMedia(
  WidgetRef ref,
  ModifiablePostEntity? story, {
  String? sessionPubkey,
  bool keepAliveForSession = false,
}) {
  final context = useContext();

  useOnInit(
    () {
      if (story == null) return;
      unawaited(
        _preloadStoryMedia(
          ref: ref,
          context: context,
          story: story,
          sessionPubkey: sessionPubkey,
          keepAliveForSession: keepAliveForSession,
        ),
      );
    },
    [story?.id, sessionPubkey, keepAliveForSession],
  );
}

Future<void> preloadStoryMedia({
  required WidgetRef ref,
  required BuildContext context,
  required ModifiablePostEntity story,
  String? sessionPubkey,
  bool keepAliveForSession = false,
}) {
  return _preloadStoryMedia(
    ref: ref,
    context: context,
    story: story,
    sessionPubkey: sessionPubkey,
    keepAliveForSession: keepAliveForSession,
  );
}
