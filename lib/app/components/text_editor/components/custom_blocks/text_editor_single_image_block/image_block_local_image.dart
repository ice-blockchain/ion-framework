// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/video_preview/video_preview.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/gallery/providers/gallery_provider.r.dart';
import 'package:ion/app/services/media_service/aspect_ratio.dart';
import 'package:photo_manager/photo_manager.dart';

class ImageBlockLocalImage extends HookConsumerWidget {
  const ImageBlockLocalImage({
    required this.path,
    super.key,
    this.authorPubkey,
  });

  final String path;
  final String? authorPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = useState<File?>(null);
    final aspectRatio = useState<double?>(null);
    final isLoading = useState(true);
    final isVideo = useState(false);
    final duration = useState<Duration?>(null);
    final thumbnailBytes = useState<Uint8List?>(null);

    useEffect(
      () {
        Future<void> loadMediaData() async {
          try {
            final assetEntity = await ref.read(assetEntityProvider(path).future);
            if (assetEntity != null) {
              aspectRatio.value = attachedMediaAspectRatio(
                [MediaAspectRatio.fromAssetEntity(assetEntity)],
              ).aspectRatio;

              isVideo.value = assetEntity.type == AssetType.video;
              duration.value = assetEntity.videoDuration;
              file.value = await assetEntity.originFile;
              thumbnailBytes.value = await assetEntity.thumbnailData;
            }
          } finally {
            if (context.mounted) {
              isLoading.value = false;
            }
          }
        }

        loadMediaData();
        return null;
      },
      [path],
    );

    if (aspectRatio.value == null || isLoading.value || file.value == null) {
      return const SizedBox.shrink();
    }

    if (isVideo.value) {
      return AspectRatio(
        aspectRatio: aspectRatio.value!,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.s),
          child: VideoPreview(
            videoUrl: file.value!.path,
            authorPubkey: authorPubkey ?? '',
            duration: duration.value,
            visibilityThreshold: 0.5,
            thumbnailBytes: thumbnailBytes.value,
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: aspectRatio.value!,
      child: Image.file(
        file.value!,
        fit: BoxFit.cover,
        width: double.infinity,
      ),
    );
  }
}
