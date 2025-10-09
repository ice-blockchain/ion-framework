// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/video_preview/video_preview.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/media_service/aspect_ratio.dart';

class ImageBlockNetworkImage extends ConsumerWidget {
  const ImageBlockNetworkImage({
    required this.path,
    required this.media,
    super.key,
    this.authorPubkey,
    this.eventReference,
  });

  final String path;
  final Map<String, MediaAttachment>? media;
  final String? authorPubkey;
  final String? eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalizedPath = 'url $path';
    final attachment = media?[normalizedPath];

    if (attachment != null) {
      final mediaType = MediaType.fromMimeType(attachment.mimeType);

      if (mediaType == MediaType.video) {
        final mediaAspectRatio = MediaAspectRatio.fromMediaAttachment(attachment);
        final aspectRatio = mediaAspectRatio.aspectRatio ?? MediaAspectRatio.landscape;

        final videoWidget = AspectRatio(
          aspectRatio: aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.s),
            child: VideoPreview(
              videoUrl: path,
              duration:
                  attachment.duration != null ? Duration(seconds: attachment.duration!) : null,
              authorPubkey: authorPubkey ?? '',
              thumbnailUrl: attachment.thumb,
              visibilityThreshold: 0.5,
            ),
          ),
        );

        return GestureDetector(
          onTap: () {
            if (eventReference != null && media != null) {
              final mediaEntries = media!.entries.toList();
              final videoIndex = mediaEntries.indexWhere((entry) => entry.key == normalizedPath);

              FullscreenMediaRoute(
                eventReference: eventReference!,
                initialMediaIndex: videoIndex >= 0 ? videoIndex : 0,
              ).push<void>(context);
            }
          },
          child: videoWidget,
        );
      }

      final mediaAspectRatio = MediaAspectRatio.fromMediaAttachment(attachment);
      if (mediaAspectRatio.aspectRatio != null) {
        final aspectRatio = attachedMediaAspectRatio([mediaAspectRatio]).aspectRatio;

        return AspectRatio(
          aspectRatio: aspectRatio,
          child: Image.network(
            path,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }
}
