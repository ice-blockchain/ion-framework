// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/video_player_provider.m.dart';
import 'package:ion/app/features/feed/stories/providers/story_feed_prefetch_registry_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/story_video_prefetch_targets_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:video_player/video_player.dart';

part 'story_video_controller_provider.m.freezed.dart';
part 'story_video_controller_provider.m.g.dart';

@Freezed(fromJson: false, toJson: false)
class StoryVideoControllerParams with _$StoryVideoControllerParams {
  const factory StoryVideoControllerParams({
    required String storyId,
    required String sessionPubkey,
    required VideoControllerParams baseParams,
  }) = _StoryVideoControllerParams;
}

@riverpod
Future<Raw<VideoPlayerController>> storyVideoController(
  Ref ref,
  StoryVideoControllerParams params,
) async {
  KeepAliveLink? keepAliveLink;

  void ensureKeepAlive() {
    keepAliveLink ??= ref.keepAlive();
  }

  // Keep the provider alive during initial controller initialization; we'll
  // release the link if neither feed nor viewer targets require it.
  ensureKeepAlive();

  void syncKeepAlive() {
    final viewerTargets = ref.read(storyVideoPrefetchTargetsProvider(params.sessionPubkey));
    final feedTargets = ref.read(storyFeedPrefetchRegistryProvider(params.sessionPubkey));
    final shouldKeepAlive =
        viewerTargets.contains(params.storyId) || feedTargets.contains(params.storyId);

    if (shouldKeepAlive) {
      ensureKeepAlive();
    } else {
      keepAliveLink?.close();
      keepAliveLink = null;
    }
  }

  ref
    ..listen<Set<String>>(
      storyVideoPrefetchTargetsProvider(params.sessionPubkey),
      (_, __) => syncKeepAlive(),
      fireImmediately: true,
    )
    ..listen<Set<String>>(
      storyFeedPrefetchRegistryProvider(params.sessionPubkey),
      (_, __) => syncKeepAlive(),
      fireImmediately: true,
    )
    ..onDispose(() {
      keepAliveLink?.close();
      keepAliveLink = null;
    });

  return ref.watch(videoControllerProvider(params.baseParams).future);
}
