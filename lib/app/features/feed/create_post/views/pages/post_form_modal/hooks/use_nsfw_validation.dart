// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/create_post/providers/media_nsfw_parallel_checker.m.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';

void useNsfwValidation({
  required List<MediaFile> mediaFiles,
  required MediaFile? videoFile,
  required WidgetRef ref,
}) {
  final mediaSignature = mediaFiles.map((f) => f.path).join(',');

  // Handle image files
  useEffect(
    () {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final mediaChecker = ref.read(mediaNsfwParallelCheckerProvider.notifier);

          if (mediaFiles.isNotEmpty) {
            final convertedMediaFiles = await ref
                .read(mediaServiceProvider)
                .convertAssetIdsToMediaFiles(ref, mediaFiles: mediaFiles);

            await mediaChecker.addMediaListCheck(convertedMediaFiles);
          } else {
            if (!mediaChecker.hasEmptyChecks) {
              // The case when we removed last media, but we still have that result kept in the state
              await mediaChecker.addMediaListCheck([]);
            }
          }
        } catch (e, st) {
          // TODO: Handle error
        }
      });
      return null;
    },
    [mediaSignature],
  );

// Handle video files
  useEffect(
    () {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final mediaChecker = ref.read(mediaNsfwParallelCheckerProvider.notifier);
          if (videoFile != null) {
            await mediaChecker.addMediaListCheck([videoFile]);
          } else {
            if (!mediaChecker.hasEmptyChecks) {
              // The case when we removed last video, but we still have that result kept in the state
              await mediaChecker.addMediaListCheck([]);
            }
          }
        } catch (e, st) {
          // TODO: Handle error
        }
      });
      return null;
    },
    [videoFile],
  );
}
