// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/core/providers/video_player_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/stories/providers/story_image_loading_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';

void usePreloadStoryMedia(WidgetRef ref, ModifiablePostEntity? story) {
  useOnInit(
    () {
      if (story == null) return;
      final media = story.data.primaryMedia;
      if (media == null) return;
      if (media.mediaType == MediaType.image) {
        // .getSingleFile() downloads a file if it's not cached yet
        ref.read(storyImageCacheManagerProvider).getSingleFile(media.url);
      } else if (media.mediaType == MediaType.video) {
        ref.read(
          videoControllerProvider(
            VideoControllerParams(sourcePath: media.url, authorPubkey: story.masterPubkey),
          ),
        );
      }
    },
    [story?.id],
  );
}
