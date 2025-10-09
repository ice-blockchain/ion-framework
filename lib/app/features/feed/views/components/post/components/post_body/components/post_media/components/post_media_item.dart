// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/video_preview/video_preview.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/feed/views/components/feed_network_image/feed_network_image.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/typedefs/typedefs.dart';

class PostMediaItem extends HookWidget {
  const PostMediaItem({
    required this.aspectRatio,
    required this.eventReference,
    required this.media,
    this.mediaIndex = 0,
    this.videoIndex = 0,
    this.onVideoTap,
    this.framedEventReference,
    super.key,
  });

  final int mediaIndex;
  final int videoIndex;
  final double aspectRatio;
  final EventReference eventReference;
  final EventReference? framedEventReference;
  final OnVideoTapCallback? onVideoTap;
  final List<MediaAttachment> media;

  @override
  Widget build(BuildContext context) {
    final mediaItem = media[mediaIndex];

    return GestureDetector(
      key: ValueKey(mediaItem.url),
      // call onVideoTap callback only on posts where all media are videos
      onTap: () => onVideoTap != null &&
              mediaItem.mediaType == MediaType.video &&
              media.every((item) => item.mediaType == MediaType.video)
          ? onVideoTap?.call(
              eventReference: eventReference.encode(),
              initialMediaIndex: videoIndex,
              framedEventReference: framedEventReference?.encode(),
            )
          : FullscreenMediaRoute(
              eventReference: eventReference.encode(),
              initialMediaIndex: mediaIndex,
              framedEventReference: framedEventReference?.encode(),
            ).push<void>(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0.s),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: switch (mediaItem.mediaType) {
            MediaType.image => LayoutBuilder(
                builder: (context, constraints) {
                  return FeedIONConnectNetworkImage(
                    imageUrl: mediaItem.url,
                    fit: BoxFit.cover,
                    authorPubkey: eventReference.masterPubkey,
                  );
                },
              ),
            MediaType.video => VideoPreview(
                videoUrl: mediaItem.url,
                duration:
                    mediaItem.duration != null ? Duration(seconds: mediaItem.duration!) : null,
                authorPubkey: eventReference.masterPubkey,
                thumbnailUrl: mediaItem.image,
                framedEventReference: framedEventReference,
                visibilityThreshold: 0.5,
              ),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}
