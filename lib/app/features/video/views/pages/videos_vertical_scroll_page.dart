// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/status_bar/status_bar_color_wrapper.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/components/quick_page_swiper/quick_page_swiper.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/providers/feed_posts_provider.r.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/feed/views/components/overlay_menu/own_entity_menu.dart';
import 'package:ion/app/features/feed/views/components/overlay_menu/user_info_menu.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/video/views/components/video_actions.dart';
import 'package:ion/app/features/video/views/components/video_not_found.dart';
import 'package:ion/app/features/video/views/components/video_post_info.dart';
import 'package:ion/app/features/video/views/hooks/use_status_bar_color.dart';
import 'package:ion/app/features/video/views/hooks/use_wake_lock.dart';
import 'package:ion/app/features/video/views/pages/video_page.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_back_button.dart';
import 'package:ion/generated/assets.gen.dart';

class _FlattenedVideo {
  _FlattenedVideo({required this.entity, required this.media});

  final IonConnectEntity entity;
  final MediaAttachment media;
}

class VideosVerticalScrollPage extends HookConsumerWidget {
  const VideosVerticalScrollPage({
    required this.eventReference,
    required this.entities,
    required this.onLoadMore,
    this.initialMediaIndex = 0,
    this.framedEventReference,
    super.key,
  });

  final EventReference eventReference;
  final int initialMediaIndex;
  final Iterable<IonConnectEntity> entities;
  final void Function() onLoadMore;
  final EventReference? framedEventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useStatusBarColor();
    useWakelock();

    final appColors = context.theme.appColors;
    final primaryTextColor = appColors.primaryText;
    final onPrimaryAccentColor = appColors.onPrimaryAccent;
    final secondaryBackgroundColor = appColors.secondaryBackground;
    final rightPadding = 6.0.s;
    final animationDuration = 100.ms;

    final ionConnectEntity =
        ref.watch(ionConnectEntityWithCountersProvider(eventReference: eventReference));

    if (ionConnectEntity == null ||
        (ionConnectEntity is! ModifiablePostEntity && ionConnectEntity is! PostEntity)) {
      return const VideoNotFound();
    }

    final filteredVideos = entities.where((item) {
      final videoPost = ref.read(isVideoPostProvider(item));
      final videoRepost = ref.read(isVideoRepostProvider(item));
      return videoPost || videoRepost;
    });

    final videos = filteredVideos.isEmpty ? [ionConnectEntity] : filteredVideos;

    final List<_FlattenedVideo> flattenedVideos = useMemoized(
      () {
        final result = <_FlattenedVideo>[];
        for (final entity in videos) {
          if (entity is ModifiablePostEntity || entity is PostEntity) {
            for (final media in _getVideosFromEntity(entity)) {
              result.add(_FlattenedVideo(entity: entity, media: media));
            }
          } else {
            final reposted = ref.read(getRepostedEntityProvider(entity));
            if (reposted != null) {
              for (final media in _getVideosFromEntity(reposted)) {
                result.add(_FlattenedVideo(entity: reposted, media: media));
              }
            }
          }
        }
        final distinctResult = result.distinctBy((video) => video.media.url);
        return distinctResult;
      },
      [entities],
    );

    final initialPage =
        flattenedVideos.indexWhere((video) => video.entity.id == ionConnectEntity.id) +
            initialMediaIndex;

    final userPageController = usePageController(initialPage: initialPage);
    final currentEventReference = useState<EventReference>(eventReference);

    final isOwnedByCurrentUser =
        ref.watch(isCurrentUserSelectorProvider(currentEventReference.value.masterPubkey));

    useEffect(
      () {
        void listener() {
          if (userPageController.offset < -150 ||
              (userPageController.offset > userPageController.position.maxScrollExtent + 150)) {
            context.pop();
          }
        }

        userPageController.addListener(listener);

        return () {
          userPageController.removeListener(listener);
        };
      },
      [userPageController],
    );

    return StatusBarColorWrapper.light(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
        backgroundColor: primaryTextColor,
        appBar: NavigationAppBar.screen(
          backgroundColor: Colors.transparent,
          leading: NavigationBackButton(
            () => context.pop(),
            icon: Assets.svg.iconChatBack.icon(
              size: NavigationAppBar.actionButtonSide,
              color: onPrimaryAccentColor,
              flipForRtl: true,
            ),
          ),
          onBackPress: () => context.pop(),
          actions: [
            Padding(
              padding: EdgeInsetsDirectional.only(end: rightPadding),
              child: isOwnedByCurrentUser
                  ? OwnEntityMenu(
                      eventReference: currentEventReference.value,
                      iconColor: secondaryBackgroundColor,
                      onDelete: () {
                        if (context.canPop()) {
                          context.pop();
                        }
                      },
                    )
                  : UserInfoMenu(
                      eventReference: currentEventReference.value,
                      iconColor: secondaryBackgroundColor,
                    ),
            ),
          ],
        ),
        body: QuickPageSwiper(
          pageController: userPageController,
          swipeDuration: animationDuration,
          child: PageView.builder(
            controller: userPageController,
            itemCount: flattenedVideos.length,
            scrollDirection: Axis.vertical,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              _loadMore(ref, index, flattenedVideos.length);
              currentEventReference.value = flattenedVideos[index].entity.toEventReference();
            },
            itemBuilder: (_, index) => VideoPage(
              videoInfo: VideoPostInfo(videoPost: flattenedVideos[index].entity),
              bottomOverlay:
                  VideoActions(eventReference: flattenedVideos[index].entity.toEventReference()),
              videoUrl: flattenedVideos[index].media.url,
              authorPubkey: eventReference.masterPubkey,
              thumbnailUrl: flattenedVideos[index].media.thumb,
              blurhash: flattenedVideos[index].media.blurhash,
              aspectRatio: flattenedVideos[index].media.aspectRatio,
              framedEventReference: index == initialPage ? framedEventReference : null,
              onVideoEnded: () {
                if (index < flattenedVideos.length - 1) {
                  userPageController.nextPage(
                    duration: animationDuration,
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  void _loadMore(WidgetRef ref, int index, int totalItems) {
    const threshold = 2;
    if (totalItems > threshold && index >= totalItems - threshold) {
      onLoadMore();
    }
  }

  List<MediaAttachment> _getVideosFromEntity(IonConnectEntity entity) {
    return switch (entity) {
      ModifiablePostEntity() => entity.data.videos,
      PostEntity() => entity.data.videos,
      _ => []
    };
  }
}
