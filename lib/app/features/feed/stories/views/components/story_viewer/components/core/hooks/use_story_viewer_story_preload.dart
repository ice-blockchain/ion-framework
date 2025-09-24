// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/stories/providers/story_video_prefetch_targets_provider.r.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/hooks/use_preload_story_media.dart';
import 'package:ion/app/hooks/use_on_init.dart';

typedef StoryPrefetchReset = VoidCallback;

StoryPrefetchReset useStoryViewerStoryPreload({
  required WidgetRef ref,
  required String sessionPubkey,
  required List<ModifiablePostEntity> stories,
  required int currentStoryIndex,
}) {
  final context = useContext();

  final prefetchTargetsProvider = storyVideoPrefetchTargetsProvider(sessionPubkey);

  String? storyIdAt(int index) {
    if (index < 0 || index >= stories.length) {
      return null;
    }
    return stories[index].id;
  }

  List<ModifiablePostEntity> computeWindowStories() {
    final windowStories = <ModifiablePostEntity>[];
    for (var offset = -2; offset <= 2; offset++) {
      if (offset == 0) continue;
      final targetIndex = currentStoryIndex + offset;
      if (targetIndex < 0 || targetIndex >= stories.length) continue;
      windowStories.add(stories[targetIndex]);
    }
    return windowStories;
  }

  useEffect(
    () {
      final notifier = ref.read(prefetchTargetsProvider.notifier);
      return () {
        Future.microtask(notifier.clear);
      };
    },
    [ref, sessionPubkey],
  );

  useOnInit(
    () {
      if (!context.mounted) return;
      if (stories.isEmpty) return;

      final windowStories = computeWindowStories();
      ref
          .read(prefetchTargetsProvider.notifier)
          .replaceWith(windowStories.map((story) => story.id));

      for (final story in windowStories) {
        unawaited(
          preloadStoryMedia(
            ref: ref,
            context: context,
            story: story,
            sessionPubkey: sessionPubkey,
          ),
        );
      }
    },
    [
      sessionPubkey,
      currentStoryIndex,
      stories.length,
      storyIdAt(currentStoryIndex - 2),
      storyIdAt(currentStoryIndex - 1),
      storyIdAt(currentStoryIndex + 1),
      storyIdAt(currentStoryIndex + 2),
    ],
  );

  return useCallback(
    () {
      ref.read(prefetchTargetsProvider.notifier).clear();
    },
    [ref, sessionPubkey],
  );
}
