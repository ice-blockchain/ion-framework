// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/nsfw/providers/media_nsfw_checker_notifier.m.dart';
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
        final mediaChecker = ref.read(mediaNsfwCheckerNotifierProvider.notifier);
        final mediaCheckerState = ref.read(mediaNsfwCheckerNotifierProvider);

        if (mediaFiles.isNotEmpty) {
          final convertedMediaFiles = await ref
              .read(mediaServiceProvider)
              .convertAssetIdsToMediaFiles(ref, mediaFiles: mediaFiles);

          await mediaChecker.checkMediaForNsfw(convertedMediaFiles);
        } else {
          if (!mediaCheckerState.isEmpty) {
            // The case when we removed last media, but we still have that result kept in the state
            mediaChecker.resetNsfwResults();
          }
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
        final mediaChecker = ref.read(mediaNsfwCheckerNotifierProvider.notifier);
        final mediaCheckerState = ref.read(mediaNsfwCheckerNotifierProvider);

        if (videoFile != null) {
          await mediaChecker.checkMediaForNsfw([videoFile]);
        } else {
          if (!mediaCheckerState.isEmpty) {
            // The case when we removed last video, but we still have that result kept in the state
            mediaChecker.resetNsfwResults();
          }
        }
      });
      return null;
    },
    [videoFile],
  );
}
