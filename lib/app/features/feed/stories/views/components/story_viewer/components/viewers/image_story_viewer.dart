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

        return SizedBox.expand(
          child: Image(
            image: imageProvider,
            fit: hasQuotedPost ? BoxFit.contain : BoxFit.cover,
          ),
        );
      },
    );

    if (hasQuotedPost) {
      final eventReference = quotedEvent?.eventReference ?? sourcePostReference?.eventReference;
      if (eventReference != null) {
        final text = eventReference.isArticleReference
            ? context.i18n.story_see_article
            : context.i18n.story_see_post;

        return ColoredBox(
          color: context.theme.appColors.primaryText,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0.s),
            child: TapToSeeHint(
              onTap: () {
                if (eventReference.isArticleReference) {
                  ArticleDetailsRoute(
                    eventReference: eventReference.encode(),
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
