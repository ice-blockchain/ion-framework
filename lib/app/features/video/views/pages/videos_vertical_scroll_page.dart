// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/bottom_sheet_menu/bottom_sheet_menu_button.dart';
import 'package:ion/app/components/overlay_menu/notifiers/overlay_menu_close_signal.dart';
import 'package:ion/app/components/status_bar/status_bar_color_wrapper.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/components/quick_page_swiper/quick_page_swiper.dart';
import 'package:ion/app/features/core/providers/video_player_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/providers/feed_posts_provider.r.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/feed/views/components/bottom_sheet_menu/own_post_menu_bottom_sheet.dart';
import 'package:ion/app/features/feed/views/components/bottom_sheet_menu/post_menu_bottom_sheet.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/video/views/components/video_actions.dart';
import 'package:ion/app/features/video/views/components/video_not_found.dart';
import 'package:ion/app/features/video/views/components/video_post_info.dart';
import 'package:ion/app/features/video/views/hooks/use_status_bar_color.dart';
import 'package:ion/app/features/video/views/hooks/use_wake_lock.dart';
import 'package:ion/app/features/video/views/pages/ad_video_page.dart';
import 'package:ion/app/features/video/views/pages/video_page.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_back_button.dart';
import 'package:ion/app/services/ion_ad/ion_ad_provider.r.dart';
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
    this.onLoadMore,
    this.initialMediaIndex = 0,
    this.framedEventReference,
    this.onVideoSeen,
    super.key,
  });

  final EventReference eventReference;
  final int initialMediaIndex;
  final Iterable<IonConnectEntity> entities;
  final void Function()? onLoadMore;
  final void Function(IonConnectEntity? video)? onVideoSeen;
  final EventReference? framedEventReference;

  bool get hasMore => onLoadMore != null;

  static const int showAdAfter = 7;

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
        ref.watch(ionConnectSyncEntityWithCountersProvider(eventReference: eventReference));

    if (ionConnectEntity == null ||
        (ionConnectEntity is! ModifiablePostEntity && ionConnectEntity is! PostEntity)) {
      return const VideoNotFound();
    }

    final filteredVideos = entities.where((item) {
      final videoPost = ref.read(isVideoPostProvider(item));
      final videoRepost = ref.read(isVideoRepostProvider(item));
      final videoReply = ref.read(isVideoReplyProvider(item));
      return videoPost || videoRepost || videoReply;
    });

    final videos = filteredVideos.isEmpty ? [ionConnectEntity] : filteredVideos.toList();

    final List<_FlattenedVideo> flattenedVideos = useMemoized(
      () {
        final currentEntityFlattenedVideo = videos.firstWhereOrNull(
          (v) => v.id == ionConnectEntity.id,
        );

        //ensuring current entity is always the first before flattening them and filtering them by distinct
        if (currentEntityFlattenedVideo != null) {
          videos
            ..remove(currentEntityFlattenedVideo)
            ..insert(0, currentEntityFlattenedVideo);
        }

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

    final menuCloseSignal = useMemoized(OverlayMenuCloseSignal.new);
    useEffect(() => menuCloseSignal.dispose, [menuCloseSignal]);

    useEffect(
      () {
        void listener() {
          if (userPageController.offset != 0) {
            menuCloseSignal.trigger();
          }

          if (userPageController.offset < -150 ||
              (userPageController.offset > userPageController.position.maxScrollExtent + 150)) {
            if (context.canPop() && !hasMore && context.mounted) {
              context.pop();
            }
          }
        }

        userPageController.addListener(listener);

        return () {
          userPageController.removeListener(listener);
        };
      },
      [userPageController],
    );

    useOnInit(
      () {
        onVideoSeen?.call(flattenedVideos[initialPage].entity);
      },
      [onVideoSeen, initialPage, flattenedVideos],
    );

    final canShowNativeAds = ref.watch(ionAdClientProvider).valueOrNull?.isNativeLoaded ?? false;
    final adPositionsRef = useRef<Set<int>>({});
    final adPositions = useMemoized(
      () {
        if (flattenedVideos.length < showAdAfter || !canShowNativeAds) return adPositionsRef.value;

        final rng = Random(flattenedVideos.length);
        var currentPos = adPositionsRef.value.isEmpty ? 0 : adPositionsRef.value.reduce(max) + 1;

        while (currentPos < flattenedVideos.length + adPositionsRef.value.length + 10) {
          // Logic: next ad after 7 +/- 3 videos
          final gap = (showAdAfter + rng.nextInt(showAdAfter) - showAdAfter / 2).toInt();
          currentPos += max(3, gap);

          adPositionsRef.value.add(currentPos);
          currentPos++;
        }
        return adPositionsRef.value;
      },
      [flattenedVideos.length, canShowNativeAds],
    );

    final isAdVisible = useState(false);
    final totalItemCount =
        flattenedVideos.length + adPositions.where((p) => p < flattenedVideos.length + 10).length;

    final nextVideoParams = useMemoized(
      () {
        final currentIndex = flattenedVideos.indexWhere(
          (v) => v.entity.toEventReference() == currentEventReference.value,
        );

        if (currentIndex != -1 && currentIndex + 1 < flattenedVideos.length) {
          final nextVideo = flattenedVideos[currentIndex + 1];
          final nextEventReference = nextVideo.entity.toEventReference();
          final nextIsInitial = (currentIndex + 1) == initialPage;

          return VideoControllerParams(
            sourcePath: nextVideo.media.url,
            authorPubkey: nextEventReference.masterPubkey,
            looping: true,
            uniqueId: nextIsInitial ? framedEventReference?.encode() ?? '' : '',
          );
        }
        return null;
      },
      [flattenedVideos, currentEventReference.value],
    );

    if (nextVideoParams != null) {
      ref.watch(videoControllerProvider(nextVideoParams));
    }

    return StatusBarColorWrapper.light(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
        backgroundColor: primaryTextColor,
        appBar: NavigationAppBar.screen(
          backgroundColor: Colors.transparent,
          leading: NavigationBackButton(
            () => context.pop(),
            showShadow: true,
            icon: Assets.svg.iconChatBack.icon(
              size: NavigationAppBar.actionButtonSide,
              color: onPrimaryAccentColor,
              flipForRtl: true,
            ),
          ),
          onBackPress: () => context.pop(),
          actions: isAdVisible.value
              ? null
              : [
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: rightPadding),
                    child: isOwnedByCurrentUser
                        ? BottomSheetMenuButton(
                            showShadow: true,
                            iconColor: secondaryBackgroundColor,
                            menuBuilder: (context) => OwnPostMenuBottomSheet(
                              eventReference: currentEventReference.value,
                              onDelete: () {
                                if (context.canPop() && context.mounted) {
                                  context.pop();
                                }
                              },
                            ),
                          )
                        : BottomSheetMenuButton(
                            showShadow: true,
                            iconColor: secondaryBackgroundColor,
                            menuBuilder: (context) => PostMenuBottomSheet(
                              eventReference: currentEventReference.value,
                            ),
                          ),
                  ),
                ],
        ),
        body: QuickPageSwiper(
          pageController: userPageController,
          swipeDuration: animationDuration,
          child: PageView.builder(
            controller: userPageController,
            itemCount: totalItemCount,
            scrollDirection: Axis.vertical,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              final adsBefore = adPositions.where((p) => p < index).length;
              final videoIndex = index - adsBefore;
              if (!adPositions.contains(index) && videoIndex < flattenedVideos.length) {
                onVideoSeen?.call(flattenedVideos[videoIndex].entity);
                _loadMore(ref, videoIndex, flattenedVideos.length);
                currentEventReference.value = flattenedVideos[videoIndex].entity.toEventReference();
              }
            },
            itemBuilder: (_, index) {
              if (adPositions.contains(index) && canShowNativeAds) {
                isAdVisible.value = true;
                final prevVideoIndex =
                    max(0, index - adPositions.where((p) => p < index).length - 1);
                return AdVideoViewer(flattenedVideos[prevVideoIndex].entity.id);
              } else {
                final adsBefore = adPositions.where((p) => p < index).length;
                final videoIndex = index - adsBefore;

                if (videoIndex >= flattenedVideos.length) return const SizedBox.shrink();

                isAdVisible.value = false;
                final flattenedVideo = flattenedVideos[videoIndex];
                final perPageEventReference = flattenedVideo.entity.toEventReference();
                final media = flattenedVideo.media;

                return VideoPage(
                  videoInfo: VideoPostInfo(videoPost: flattenedVideo.entity),
                  bottomOverlay: VideoActions(
                    eventReference: perPageEventReference,
                    onReplyTap: () => PostDetailsRoute(
                      eventReference: perPageEventReference.encode(),
                    ).push<void>(context),
                  ),
                  videoUrl: media.url,
                  authorPubkey: perPageEventReference.masterPubkey,
                  thumbnailUrl: media.thumb,
                  blurhash: media.blurhash,
                  aspectRatio: media.aspectRatio,
                  framedEventReference: index == initialPage ? framedEventReference : null,
                );
              }
            },
          ),
        ),
      ),
    );
  }

  void _loadMore(WidgetRef ref, int index, int totalItems) {
    const threshold = 2;
    if (hasMore && index >= totalItems - threshold) {
      onLoadMore?.call();
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
