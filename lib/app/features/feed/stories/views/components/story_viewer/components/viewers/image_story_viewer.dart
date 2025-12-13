// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/progress_bar/centered_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/ion_connect_network_image/ion_connect_network_image.dart';
import 'package:ion/app/features/feed/stories/providers/story_image_loading_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/story_pause_provider.r.dart';
import 'package:ion/app/features/feed/stories/views/components/story_viewer/components/viewers/tap_to_see_hint.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/quoted_event.f.dart';
import 'package:ion/app/features/ion_connect/model/source_post_reference.f.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class ImageStoryViewer extends HookConsumerWidget {
  const ImageStoryViewer({
    required this.imageUrl,
    required this.authorPubkey,
    required this.storyId,
    this.quotedEvent,
    this.sourcePostReference,
    super.key,
  });

  final String imageUrl;
  final String authorPubkey;
  final String storyId;
  final QuotedEvent? quotedEvent;
  final SourcePostReference? sourcePostReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheManager = ref.watch(storyImageCacheManagerProvider);

    final hasQuotedPost = quotedEvent != null || sourcePostReference != null;
    final isProfileScreenshot = sourcePostReference?.eventReference.isProfileReference ?? false;

    // Keep the provider alive as long as the image is being displayed
    ref.watch(storyImageLoadStatusProvider(storyId));

    final imageWidget = IonConnectNetworkImage(
      imageUrl: imageUrl,
      authorPubkey: authorPubkey,
      cacheManager: cacheManager,
      filterQuality: FilterQuality.high,
      placeholder: (_, __) => const CenteredLoadingIndicator(),
      imageBuilder: (context, imageProvider) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ref.read(storyImageLoadStatusProvider(storyId).notifier).markLoaded();
          }
        });

        // For profile screenshots, use cover to fill width; for quoted posts, use contain
        final fit =
            isProfileScreenshot ? BoxFit.cover : (hasQuotedPost ? BoxFit.contain : BoxFit.cover);

        return SizedBox.expand(
          child: Image(
            image: imageProvider,
            fit: fit,
          ),
        );
      },
    );

    if (hasQuotedPost) {
      final eventReference = quotedEvent?.eventReference ?? sourcePostReference?.eventReference;
      if (eventReference != null) {
        final text = eventReference.isArticleReference
            ? context.i18n.story_see_article
            : eventReference.isProfileReference
                ? context.i18n.story_see_profile
                : context.i18n.story_see_post;

        // For profile screenshots, don't add padding to allow full width
        final padding =
            isProfileScreenshot ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: 20.0.s);

        return ColoredBox(
          color: context.theme.appColors.primaryText,
          child: Padding(
            padding: padding,
            child: TapToSeeHint(
              onTap: () {
                if (eventReference.isArticleReference) {
                  ArticleDetailsRoute(
                    eventReference: eventReference.encode(),
                  ).push<void>(context);
                } else if (eventReference.isProfileReference) {
                  ProfileRoute(
                    pubkey: eventReference.masterPubkey,
                  ).push<void>(context);
                } else {
                  PostDetailsRoute(
                    eventReference: eventReference.encode(),
                  ).push<void>(context);
                }
              },
              text: text,
              onVisibilityChanged: (isVisible) {
                ref.read(storyPauseControllerProvider.notifier).paused = isVisible;
              },
              child: imageWidget,
            ),
          ),
        );
      }
    }

    return imageWidget;
  }
}
