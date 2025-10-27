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
      if (mediaFiles.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            final convertedMediaFiles = await ref
                .read(mediaServiceProvider)
                .convertAssetIdsToMediaFiles(ref, mediaFiles: mediaFiles);

            await ref
                .read(mediaNsfwParallelCheckerProvider.notifier)
                .addMediaListCheck(convertedMediaFiles);
          } catch (e) {
            // Handle conversion errors
          }
        });
      }
      return null;
    },
    [mediaSignature],
  );

  // Handle video files
  useEffect(
    () {
      if (videoFile != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            await ref
                .read(mediaNsfwParallelCheckerProvider.notifier)
                .addMediaListCheck([videoFile]);
          } catch (e) {
            // Handle video validation errors
          }
        });
      }
      return null;
    },
    [videoFile],
  );
}
