// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/status_bar/status_bar_color_wrapper.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/views/pages/chat_media_page/components/chat_media_context_menu.dart';
import 'package:ion/app/features/chat/views/pages/chat_media_page/components/chat_media_page_view.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/core/providers/mute_provider.r.dart';
import 'package:ion/app/features/feed/views/pages/fullscreen_media/hooks/use_image_zoom.dart';
import 'package:ion/app/features/feed/views/pages/fullscreen_media/providers/image_zoom_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/video/views/hooks/use_status_bar_color.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_back_button.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';

class ChatMediaPage extends HookConsumerWidget {
  const ChatMediaPage({
    required this.eventReference,
    required this.initialIndex,
    super.key,
  });

  final EventReference eventReference;
  final int initialIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useStatusBarColor();
    final currentPage = useState(initialIndex);

    final pageController = usePageController(initialPage: initialIndex);
    final zoomController = useImageZoom(ref, withReset: true);

    useEffect(
      () {
        void listener() {
          if (pageController.hasClients && pageController.page != null) {
            final newPage = pageController.page!.round();
            if (newPage != currentPage.value) {
              currentPage.value = newPage;
              zoomController.resetZoom?.call();
            }
          }
        }

        pageController.addListener(listener);

        return () {
          if (pageController.hasClients) {
            pageController.removeListener(listener);
          }
        };
      },
      [pageController, zoomController],
    );

    final isZoomed = ref.watch(imageZoomProvider);

    final eventMessageFuture = useFuture(
      useMemoized(
        () => ref.watch(eventMessageDaoProvider).getByReference(eventReference),
        [eventReference],
      ),
    );

    if (!eventMessageFuture.hasData) {
      return const SizedBox.shrink();
    }

    final eventMessage = eventMessageFuture.data!;
    final entity = ReplaceablePrivateDirectMessageEntity.fromEventMessage(eventMessage);
    final medias = entity.data.visualMedias
        .where((e) => !entity.data.visualMedias.any((c) => c.thumb == e.url && c.url != e.url))
        .toList();

    return StatusBarColorWrapper.light(
      child: Scaffold(
        backgroundColor: context.theme.appColors.primaryText,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            ChatMediaPageView(
              medias: medias,
              eventReference: eventReference,
              initialIndex: initialIndex,
              zoomController: zoomController,
              isZoomed: isZoomed,
              pageController: pageController,
            ),
            PositionedDirectional(
              top: 0,
              start: 0,
              end: 0,
              child: ColoredBox(
                color: context.theme.appColors.primaryText.withValues(alpha: 0.5),
                child: NavigationAppBar.screen(
                  backgroundColor: Colors.transparent,
                  leading: NavigationBackButton(
                    () => context.pop(),
                    icon: Assets.svg.iconChatBack.icon(
                      size: NavigationAppBar.actionButtonSide,
                      color: context.theme.appColors.onPrimaryAccent,
                      flipForRtl: true,
                    ),
                  ),
                  onBackPress: () => context.pop(),
                  actions: [
                    ChatMediaContextMenu(
                      eventMessage: eventMessage,
                      activeMedia: medias[currentPage.value],
                    ),
                  ],
                  title: _MediaPagerCounter(
                    currentPage: currentPage.value,
                    totalPages: medias.length,
                  ),
                ),
              ),
            ),
            _MediaBottomOverlay(
              messageEntity: entity,
              medias: medias,
              currentIndex: currentPage.value,
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaPagerCounter extends StatelessWidget {
  const _MediaPagerCounter({
    required this.currentPage,
    required this.totalPages,
  });

  final int currentPage;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${currentPage + 1}/$totalPages',
      style: context.theme.appTextThemes.subtitle2.copyWith(
        color: context.theme.appColors.onPrimaryAccent,
      ),
    );
  }
}

class _MediaBottomOverlay extends ConsumerWidget {
  const _MediaBottomOverlay({
    required this.messageEntity,
    required this.medias,
    required this.currentIndex,
  });

  final ReplaceablePrivateDirectMessageEntity messageEntity;
  final List<MediaAttachment> medias;
  final int currentIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMetadata = ref.watch(userPreviewDataProvider(messageEntity.masterPubkey)).valueOrNull;

    if (userMetadata == null) {
      return const SizedBox.shrink();
    }

    final isVideo = medias[currentIndex].mediaTypeEncrypted == MediaType.video;
    final isMuted = ref.watch(globalMuteNotifierProvider);

    return PositionedDirectional(
      bottom: 0,
      start: 0,
      end: 0,
      child: SizedBox(
        height: 91.s + MediaQuery.paddingOf(context).bottom,
        child: ScreenSideOffset.small(
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              top: 12.0.s,
            ),
            child: Align(
              alignment: AlignmentDirectional.topCenter,
              child: Row(
                children: [
                  Expanded(
                    child: IntrinsicHeight(
                      child: BadgesUserListItem(
                        masterPubkey: messageEntity.masterPubkey,
                        title: Text(
                          userMetadata.data.trimmedDisplayName,
                          style: context.theme.appTextThemes.subtitle3.copyWith(
                            color: context.theme.appColors.onPrimaryAccent,
                          ),
                        ),
                        subtitle: Text(
                          prefixUsername(username: userMetadata.data.name, context: context),
                          style: context.theme.appTextThemes.caption.copyWith(
                            color: context.theme.appColors.onPrimaryAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isVideo)
                    GestureDetector(
                      onTap: () async {
                        await HapticFeedback.lightImpact();
                        if (context.mounted) {
                          await ref.read(globalMuteNotifierProvider.notifier).toggle();
                        }
                      },
                      child: isMuted
                          ? Assets.svg.iconChannelMute.icon(
                              size: 24.0.s,
                              color: context.theme.appColors.onPrimaryAccent,
                            )
                          : Assets.svg.iconChannelUnmute.icon(
                              size: 24.0.s,
                              color: context.theme.appColors.onPrimaryAccent,
                            ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
