// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/progress_bar/centered_loading_indicator.dart';
import 'package:ion/app/components/separated/separated_row.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/providers/event_share_url_provider.r.dart';
import 'package:ion/app/features/chat/providers/share_options_provider.r.dart';
import 'package:ion/app/features/chat/views/pages/share_via_message_modal/components/share_copy_link_option.dart';
import 'package:ion/app/features/chat/views/pages/share_via_message_modal/components/share_options_menu_item.dart';
import 'package:ion/app/features/chat/views/pages/share_via_message_modal/components/share_post_to_story_content.dart';
import 'package:ion/app/features/chat/views/pages/share_via_message_modal/components/share_profile_to_story_content.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/providers/repost_notifier.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/deep_link/shared_content_type.dart';
import 'package:ion/app/services/media_service/image_proccessing_config.dart';
import 'package:ion/app/services/share/social_share_service.r.dart';
import 'package:ion/app/utils/screenshot_utils.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:mime/mime.dart';

class ShareOptions extends HookConsumerWidget {
  const ShareOptions({required this.eventReference, super.key});

  final EventReference eventReference;

  static double get iconSize => 28.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCapturing = useState(false);

    final userPreviewData = eventReference.kind == CommunityTokenDefinitionEntity.kind
        ? null
        : ref.watch(userPreviewDataProvider(eventReference.masterPubkey)).valueOrNull;
    if (userPreviewData == null && eventReference.kind != CommunityTokenDefinitionEntity.kind) {
      return const SizedBox.shrink();
    }
    final shareOptionsData = ref.watch(
      shareOptionsDataProvider(
        eventReference,
        userPreviewData?.data,
        prefixUsername(username: userPreviewData?.data.name, context: context),
      ),
    );

    final shareUrl = ref.watch(eventShareUrlProvider(eventReference)).valueOrNull;
    if (shareUrl == null || shareOptionsData == null) {
      return const SizedBox.shrink();
    }

    final (title, description) = _buildDescription(context, shareOptionsData);
    final contentType = shareOptionsData.contentType;

    final entity = ref.watch(ionConnectEntityProvider(eventReference: eventReference)).valueOrNull;

    final canShareToStory = switch (entity) {
      ModifiablePostEntity() when !entity.isStory => true,
      ArticleEntity() => true,
      UserMetadataEntity() => true,
      _ => false,
    };

    final canShareToFeed = switch (entity) {
      CommunityTokenDefinitionEntity() => true,
      _ => false,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsetsDirectional.only(top: 20.0.s, end: 16.0.s, start: 16.0.s),
        child: SeparatedRow(
          separator: SizedBox(width: 12.0.s),
          children: [
            if (canShareToStory)
              ShareOptionsMenuItem(
                buttonType: ButtonType.primary,
                icon: isCapturing.value
                    ? const CenteredLoadingIndicator()
                    : Assets.svg.iconFeedStory.icon(size: iconSize),
                label: context.i18n.feed_add_story,
                onPressed: isCapturing.value ? () {} : () => _onShareToStory(ref, isCapturing),
              ),
            if (canShareToFeed)
              ShareOptionsMenuItem(
                buttonType: ButtonType.dropdown,
                icon: Assets.svg.iconProfileFeed
                    .icon(size: iconSize, color: context.theme.appColors.primaryText),
                label: context.i18n.post_on_feed,
                onPressed: () {
                  _onShareToFeed(ref, context, eventReference, isCapturing);
                },
              ),
            ShareCopyLinkOption(
              shareUrl: shareUrl,
              iconSize: iconSize,
              title: title,
              imageUrl: shareOptionsData.imageUrl,
              description: description,
              contentType: contentType,
            ),
            ShareOptionsMenuItem(
              buttonType: ButtonType.dropdown,
              icon: Assets.svg.iconFeedWhatsapp.icon(size: iconSize),
              label: context.i18n.feed_whatsapp,
              onPressed: () {
                ref.read(socialShareServiceProvider).shareToWhatsApp(
                      shareUrl,
                      title: title,
                      contentType: contentType,
                      imageUrl: shareOptionsData.imageUrl,
                      description: description,
                    );
              },
            ),
            ShareOptionsMenuItem(
              buttonType: ButtonType.dropdown,
              icon: Assets.svg.iconFeedTelegram.icon(size: iconSize),
              label: context.i18n.feed_telegram,
              onPressed: () {
                ref.read(socialShareServiceProvider).shareToTelegram(
                      shareUrl,
                      title: title,
                      contentType: contentType,
                      imageUrl: shareOptionsData.imageUrl,
                      description: description,
                    );
              },
            ),
            ShareOptionsMenuItem(
              buttonType: ButtonType.dropdown,
              icon: Assets.svg.iconLoginXlogo.icon(size: iconSize),
              label: context.i18n.feed_x,
              onPressed: () {
                ref.read(socialShareServiceProvider).shareToTwitter(
                      shareUrl,
                      title: title,
                      contentType: contentType,
                      imageUrl: shareOptionsData.imageUrl,
                      description: description,
                    );
              },
            ),
            ShareOptionsMenuItem(
              buttonType: ButtonType.dropdown,
              icon: Assets.svg.iconFeedMore.icon(size: iconSize),
              label: context.i18n.feed_more,
              onPressed: () {
                ref.read(socialShareServiceProvider).shareToMore(
                      shareUrl: shareUrl,
                      title: title,
                      contentType: contentType,
                      imageUrl: shareOptionsData.imageUrl,
                      description: description,
                    );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onShareToStory(WidgetRef ref, ValueNotifier<bool> isCapturing) async {
    final context = ref.context;
    isCapturing.value = true;
    final parentContainer = ProviderScope.containerOf(context);
    final childContainer = ProviderContainer(parent: parentContainer);

    try {
      final contentWidget = UncontrolledProviderScope(
        container: childContainer,
        child: eventReference.isProfileReference
            ? ShareProfileToStoryContent(eventReference: eventReference)
            : SharePostToStoryContent(eventReference: eventReference),
      );

      File? tempFile;
      if (eventReference.isProfileReference) {
        // For profile references, use story dimensions
        const storyConfig = ImageProcessingConstants.story;
        final targetWidth = storyConfig.targetWidth.toDouble();
        final targetHeight = storyConfig.targetHeight.toDouble();

        tempFile = await captureWidgetScreenshot(
          context: context,
          widget: contentWidget,
          width: targetWidth,
          height: targetHeight,
        );
      } else {
        tempFile = await captureWidgetScreenshot(
          context: context,
          widget: contentWidget,
        );
      }
      if (tempFile != null && context.mounted) {
        context.pop();
        await StoryPreviewRoute(
          path: tempFile.path,
          mimeType: lookupMimeType(tempFile.path),
          eventReference: eventReference.encode(),
          isPostScreenshot: true,
        ).push<void>(context);
      }
    } finally {
      childContainer.dispose();
      if (context.mounted) {
        isCapturing.value = false;
      }
    }
  }

  void _onShareToFeed(
    WidgetRef ref,
    BuildContext context,
    EventReference eventReference,
    ValueNotifier<bool> isCapturing,
  ) {
    ref.read(repostNotifierProvider.notifier).repost(eventReference: eventReference);
    context.pop();
  }

  (String title, String description) _buildDescription(
    BuildContext context,
    ShareOptionsData data,
  ) {
    if (data.contentType == SharedContentType.communityToken) {
      return (data.tickerName ?? '', data.tokenTitle ?? '');
    }
    final effectiveUserDisplayName = context.i18n.share_user_on_app(
      data.shareAppName,
      data.userDisplayName,
    );

    final description = switch (data.contentType) {
      SharedContentType.story => context.i18n.share_story_watch_message(effectiveUserDisplayName),
      SharedContentType.post => data.content.emptyOrValue,
      SharedContentType.postWithVideo => data.content.emptyOrValue,
      SharedContentType.article => data.articleTitle ?? '',
      SharedContentType.profile => data.userDisplayName,
      _ => '',
    };

    return (effectiveUserDisplayName, description);
  }
}
