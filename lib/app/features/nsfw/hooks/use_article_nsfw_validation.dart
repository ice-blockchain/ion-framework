// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/nsfw/providers/media_nsfw_checker.r.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';

/// Article-specific NSFW validation hook.
///
/// Unlike [useNsfwValidation], articles have a mix of media types that can't
/// be handled by a single `skipMediaConversion` flag:
///   - Cover image: already a real file path (from image processor).
///   - Content images: asset IDs from the editor (need `convertAssetIdsToMediaFiles`).
///
/// This hook resolves content images from asset IDs, combines them with the
/// cover image, and checks everything in one batch via [MediaNsfwChecker].
void useArticleNsfwValidation({
  required WidgetRef ref,
  MediaFile? coverImage,
  List<String> contentImageIds = const [],
}) {
  final signature = [
    coverImage?.path ?? '',
    ...contentImageIds,
  ].join(',');

  useEffect(
    () {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final mediaChecker = await ref.read(mediaNsfwCheckerProvider.future);

        final contentMediaFiles = contentImageIds.isNotEmpty
            ? await ref.read(mediaServiceProvider).convertAssetIdsToMediaFiles(
                  ref,
                  mediaFiles: contentImageIds.map((id) => MediaFile(path: id)).toList(),
                )
            : <MediaFile>[];

        final allMedia = [
          if (coverImage != null) coverImage,
          ...contentMediaFiles,
        ];

        if (allMedia.isNotEmpty) {
          await mediaChecker.checkMediaForNsfw(allMedia);
        } else if (!mediaChecker.isEmpty) {
          mediaChecker.reset();
        }
      });
      return null;
    },
    [signature],
  );
}
