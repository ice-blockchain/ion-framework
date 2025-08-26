// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/feed/views/components/post/components/post_body/components/post_media/components/post_media_index_indicator.dart';
import 'package:ion/app/features/feed/views/components/post/components/post_body/components/post_media/components/post_media_item.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/typedefs/typedefs.dart';

class PostMediaCarouselVertical extends HookConsumerWidget {
  const PostMediaCarouselVertical({
    required this.media,
    required this.aspectRatio,
    required this.eventReference,
    this.framedEventReference,
    this.onVideoTap,
    super.key,
  });

  static const double _viewportFraction = 0.7;

  final List<MediaAttachment> media;
  final double aspectRatio;
  final EventReference eventReference;
  final EventReference? framedEventReference;
  final OnVideoTapCallback? onVideoTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemWidth = MediaQuery.sizeOf(context).width * _viewportFraction;

    return SizedBox(
      height: itemWidth / aspectRatio,
      child: ListView.separated(
        itemCount: media.length,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: ScreenSideOffset.defaultSmallMargin,
        ),
        separatorBuilder: (context, index) {
          return SizedBox(
            width: 12.0.s,
          );
        },
        itemBuilder: (context, index) {
          return SizedBox(
            width: itemWidth,
            child: Stack(
              children: [
                PostMediaItem(
                  media: media,
                  mediaIndex: index,
                  videoIndex: media[index].mediaType == MediaType.video
                      ? media.take(index + 1).where((m) => m.mediaType == MediaType.video).length -
                          1
                      : 0,
                  aspectRatio: aspectRatio,
                  eventReference: eventReference,
                  onVideoTap: onVideoTap,
                  framedEventReference: framedEventReference,
                ),
                PostMediaIndexIndicator(
                  currentIndex: index,
                  mediaCount: media.length,
                  endPadding: 8.0.s,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
