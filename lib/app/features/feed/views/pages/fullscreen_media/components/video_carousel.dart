// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/video/views/components/video_actions.dart';
import 'package:ion/app/features/video/views/components/video_post_info.dart';
import 'package:ion/app/features/video/views/hooks/use_wake_lock.dart';
import 'package:ion/app/features/video/views/pages/video_page.dart';

class VideoCarousel extends HookWidget {
  const VideoCarousel({
    required this.videos,
    required this.initialIndex,
    required this.eventReference,
    this.post,
    this.article,
    this.framedEventReference,
    super.key,
  }) : assert(post != null || article != null, 'Either post or article must be provided');

  final List<MediaAttachment> videos;
  final int initialIndex;
  final EventReference eventReference;
  final ModifiablePostEntity? post;
  final ArticleEntity? article;
  final EventReference? framedEventReference;

  @override
  Widget build(BuildContext context) {
    final pageController = usePageController(initialPage: initialIndex);
    final currentPage = useState(initialIndex);

    useEffect(
      () {
        void listener() {
          if (pageController.page != null) {
            currentPage.value = pageController.page!.round();
          }
        }

        pageController.addListener(listener);
        return () => pageController.removeListener(listener);
      },
      [pageController],
    );

    useWakelock();

    final entity = (post ?? article!) as IonConnectEntity;

    return PageView.builder(
      controller: pageController,
      scrollDirection: Axis.vertical,
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return VideoPage(
          key: ValueKey('video_${video.url}'),
          videoInfo: VideoPostInfo(videoPost: entity),
          bottomOverlay: VideoActions(eventReference: eventReference),
          videoUrl: video.url,
          authorPubkey: eventReference.masterPubkey,
          thumbnailUrl: video.thumb,
          blurhash: video.blurhash,
          aspectRatio: video.aspectRatio,
          framedEventReference: framedEventReference,
        );
      },
    );
  }
}
