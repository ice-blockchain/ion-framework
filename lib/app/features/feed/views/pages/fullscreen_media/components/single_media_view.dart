// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/counter_items_footer/counter_items_footer.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/views/pages/fullscreen_media/components/fullscreen_image.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/video/views/components/video_actions.dart';
import 'package:ion/app/features/video/views/components/video_post_info.dart';
import 'package:ion/app/features/video/views/hooks/use_wake_lock.dart';
import 'package:ion/app/features/video/views/pages/video_page.dart';

class SingleMediaView extends HookWidget {
  const SingleMediaView({
    required this.media,
    required this.eventReference,
    this.post,
    this.article,
    this.framedEventReference,
    super.key,
  }) : assert(post != null || article != null, 'Either post or article must be provided');

  final MediaAttachment media;
  final EventReference eventReference;
  final ModifiablePostEntity? post;
  final ArticleEntity? article;
  final EventReference? framedEventReference;

  @override
  Widget build(BuildContext context) {
    final onPrimaryAccentColor = context.theme.appColors.onPrimaryAccent;
    final horizontalPadding = 16.0.s;

    useWakelock();

    if (media.mediaType == MediaType.video) {
      final entity = (post ?? article!) as IonConnectEntity;
      return VideoPage(
        videoInfo: VideoPostInfo(videoPost: entity),
        bottomOverlay: VideoActions(eventReference: eventReference),
        videoUrl: media.url,
        authorPubkey: eventReference.masterPubkey,
        thumbnailUrl: media.thumb,
        blurhash: media.blurhash,
        aspectRatio: media.aspectRatio,
        framedEventReference: framedEventReference,
      );
    }

    return FullscreenImage(
      imageUrl: media.url,
      authorPubkey: eventReference.masterPubkey,
      bottomOverlayBuilder: (context) => SafeArea(
        top: false,
        child: ColoredBox(
          color: Colors.transparent,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: CounterItemsFooter(
              eventReference: eventReference,
              color: onPrimaryAccentColor,
              itemPadding: EdgeInsetsDirectional.symmetric(vertical: 12.0.s),
            ),
          ),
        ),
      ),
    );
  }
}
