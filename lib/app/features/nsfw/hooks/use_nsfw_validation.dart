// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/nsfw/providers/media_nsfw_checker.r.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';

void useNsfwValidation({
  required List<MediaFile> mediaFiles,
  required WidgetRef ref,
  MediaFile? videoFile,
  bool skipMediaConversion = false,
  bool skipValidation = false,
}) {
  final mediaSignature = mediaFiles.map((f) => f.path).join(',');

  // Handle image files
  useEffect(
    () {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (skipValidation) return;
        final mediaChecker = await ref.read(mediaNsfwCheckerProvider.future);

        if (mediaFiles.isNotEmpty) {
          final filesToCheck = skipMediaConversion
              ? mediaFiles
              : await ref
                  .read(mediaServiceProvider)
                  .convertAssetIdsToMediaFiles(ref, mediaFiles: mediaFiles);

          await mediaChecker.checkMediaForNsfw(filesToCheck);
        } else {
          // The case when we removed last media, but we still have that result kept in the state.
          // Only reset when the other handler has no media too, so we don't clear its entries.
          if (!mediaChecker.isEmpty && videoFile == null) {
            mediaChecker.reset();
          }
        }
      });
      return null;
    },
    [mediaSignature, skipValidation],
  );

  // Handle video files
  useEffect(
    () {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (skipValidation) return;
        final mediaChecker = await ref.read(mediaNsfwCheckerProvider.future);

        if (videoFile != null) {
          await mediaChecker.checkMediaForNsfw([videoFile]);
        } else {
          // The case when we removed last video, but we still have that result kept in the state.
          // Only reset when the other handler has no media too, so we don't clear its entries.
          if (!mediaChecker.isEmpty && mediaFiles.isEmpty) {
            mediaChecker.reset();
          }
        }
      });
      return null;
    },
    [videoFile?.path, skipValidation],
  );
}
