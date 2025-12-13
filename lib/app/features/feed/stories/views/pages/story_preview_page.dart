// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/progress_bar/centered_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/feed/create_post/model/create_post_option.dart';
import 'package:ion/app/features/feed/create_post/providers/create_post_notifier.m.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_result_data.f.dart';
import 'package:ion/app/features/feed/providers/feed_video_playback_enabled.r.dart';
import 'package:ion/app/features/feed/providers/selected_entity_language_notifier.r.dart';
import 'package:ion/app/features/feed/providers/selected_interests_notifier.r.dart';
import 'package:ion/app/features/feed/providers/selected_who_can_reply_option_provider.r.dart';
import 'package:ion/app/features/feed/stories/data/models/story_preview_result.f.dart';
import 'package:ion/app/features/feed/stories/providers/current_user_feed_story_provider.r.dart';
import 'package:ion/app/features/feed/stories/views/components/story_preview/actions/story_language_button.dart';
import 'package:ion/app/features/feed/stories/views/components/story_preview/actions/story_share_button.dart';
import 'package:ion/app/features/feed/stories/views/components/story_preview/actions/story_topics_button.dart';
import 'package:ion/app/features/feed/stories/views/components/story_preview/media/post_screenshot_preview.dart';
import 'package:ion/app/features/feed/stories/views/components/story_preview/media/story_image_preview.dart';
import 'package:ion/app/features/feed/stories/views/components/story_preview/media/story_video_preview.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/services/compressors/image_compressor.r.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';

class StoryPreviewPage extends HookConsumerWidget {
  const StoryPreviewPage({
    required this.path,
    required this.mimeType,
    this.eventReference,
    this.isPostScreenshot = false,
    this.fromEditor = false,
    this.originalFilePath,
    super.key,
  });

  final String path;
  final String? mimeType;
  final EventReference? eventReference;
  final bool isPostScreenshot;
  final bool fromEditor;
  final String? originalFilePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaType = mimeType != null ? MediaType.fromMimeType(mimeType!) : MediaType.unknown;

    useEffect(
      () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(feedVideoPlaybackEnabledNotifierProvider.notifier).disablePlayback();
        });
        return null;
      },
    );

    ref
      ..displayErrors(createPostNotifierProvider(CreatePostOption.story))
      ..listenSuccess(
        createPostNotifierProvider(CreatePostOption.story),
        (_) {
          if (context.mounted && context.canPop()) {
            context.popUntil((route) {
              final isStoryRoute = route.path.startsWith('/${FeedRoutes.storyRoutePrefix}');
              final isShareRoute = route.path.startsWith('/${ChatRoutes.shareRoutePrefix}');
              final isMainModalRoute = route.path == AppRoutes.mainModalPath;

              return !isStoryRoute && !isShareRoute && !isMainModalRoute;
            });
          }
        },
      );

    final shouldUseCustomBack = fromEditor && originalFilePath != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            NavigationAppBar.modal(
              title: Text(
                context.i18n.story_preview_title,
                style: context.theme.appTextThemes.subtitle2,
              ),
              onBackPress: shouldUseCustomBack
                  ? () => context.pop(
                        StoryPreviewResult.edited(
                          originalPath: originalFilePath!,
                          mimeType: mimeType!,
                        ),
                      )
                  : null,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28.0.s),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: switch (mediaType) {
                        MediaType.video => StoryVideoPreview(path: path),
                        MediaType.image => isPostScreenshot
                            ? PostScreenshotPreview(path: path, eventReference: eventReference)
                            : StoryImagePreview(path: path),
                        MediaType.audio => const CenteredLoadingIndicator(),
                        MediaType.unknown => const CenteredLoadingIndicator(),
                      },
                    ),
                    SizedBox(height: 18.0.s),
                    const StoryTopicsButton(),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 7.s),
                      child: const HorizontalSeparator(),
                    ),
                    const StoryLanguageButton(),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 6.s),
                      child: const HorizontalSeparator(),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                SizedBox(height: 10.0.s),
                _StoryShareButton(
                  eventReference: eventReference,
                  mediaType: mediaType,
                  path: path,
                  mimeType: mimeType,
                  isPostScreenshot: isPostScreenshot,
                ),
                ScreenBottomOffset(margin: 16.0.s),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryShareButton extends HookConsumerWidget {
  const _StoryShareButton({
    required this.eventReference,
    required this.mediaType,
    required this.path,
    required this.mimeType,
    required this.isPostScreenshot,
  });

  final EventReference? eventReference;
  final MediaType mediaType;
  final String path;
  final String? mimeType;
  final bool isPostScreenshot;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPublishing = useState(false);
    final whoCanReply = ref.watch(selectedWhoCanReplyOptionProvider);
    return StoryShareButton(
      isLoading: isPublishing.value,
      onPressed: isPublishing.value
          ? null
          : () async {
              final language = ref.read(selectedEntityLanguageNotifierProvider);
              if (language == null) {
                unawaited(EntityLanguageWarningRoute().push<void>(context));
                return;
              }

              isPublishing.value = true;

              final createPostNotifier = ref.read(
                createPostNotifierProvider(CreatePostOption.story).notifier,
              );

              if (eventReference != null || mediaType == MediaType.image) {
                final dimensions =
                    await ref.read(imageCompressorProvider).getImageDimension(path: path);

                await createPostNotifier.create(
                  mediaFiles: [
                    MediaFile(
                      path: path,
                      mimeType: mimeType,
                      width: dimensions.width,
                      height: dimensions.height,
                    ),
                  ],
                  whoCanReply: whoCanReply,
                  quotedEvent: isPostScreenshot ? null : eventReference,
                  sourcePostReference: isPostScreenshot ? eventReference : null,
                  topics: ref.read(selectedInterestsNotifierProvider),
                  language: language.value,
                );
              } else if (mediaType == MediaType.video) {
                await createPostNotifier.create(
                  mediaFiles: [MediaFile(path: path, mimeType: mimeType)],
                  whoCanReply: whoCanReply,
                  topics: ref.read(selectedInterestsNotifierProvider),
                  language: language.value,
                );
              }
              if (context.mounted) {
                refreshProviders(ref);

                isPublishing.value = false;
              }
            },
    );
  }

  void refreshProviders(WidgetRef ref) {
    ref.read(feedVideoPlaybackEnabledNotifierProvider.notifier).enablePlayback();

    final pubkey = ref.read(currentPubkeySelectorProvider) ?? '';
    ref.read(currentUserFeedStoryProvider.notifier).refresh();
    ref.read(ionConnectCacheProvider.notifier).remove(
          EventCountResultEntity.cacheKeyBuilder(
            key: pubkey,
            type: EventCountResultType.stories,
          ),
        );
  }
}
