// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/progress_bar/centered_loading_indicator.dart';
import 'package:ion/app/components/separated/separated_row.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/features/chat/providers/event_share_url_provider.r.dart';
import 'package:ion/app/features/chat/views/pages/share_via_message_modal/components/share_copy_link_option.dart';
import 'package:ion/app/features/chat/views/pages/share_via_message_modal/components/share_options_menu_item.dart';
import 'package:ion/app/features/chat/views/pages/share_via_message_modal/components/share_post_to_story_content.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/share/social_share_service.r.dart';
import 'package:ion/app/utils/screenshot_utils.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:mime/mime.dart';

class ShareOptions extends HookConsumerWidget {
  const ShareOptions({required this.eventReference, super.key});

  final EventReference eventReference;

  static double get iconSize => 28.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCapturing = useState(false);

    final entity = ref.watch(ionConnectEntityProvider(eventReference: eventReference)).valueOrNull;
    final shareUrl = ref.watch(eventShareUrlProvider(eventReference)).valueOrNull;
    final userMetadata = ref.watch(userMetadataProvider(eventReference.masterPubkey)).valueOrNull;

    if (entity == null || shareUrl == null || userMetadata == null) {
      return const SizedBox.shrink();
    }

    final isPostOrStory = entity is ModifiablePostEntity;

    final isPost = isPostOrStory && entity.data.expiration == null;
    final userDisplayName = userMetadata.data.displayName;

    final (content, imageUrl) = _getContentAndImageUrl(entity, userMetadata);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsetsDirectional.only(top: 20.0.s, end: 16.0.s, start: 16.0.s),
        child: SeparatedRow(
          separator: SizedBox(width: 12.0.s),
          children: [
            if (isPost)
              ShareOptionsMenuItem(
                buttonType: ButtonType.primary,
                icon: isCapturing.value
                    ? const CenteredLoadingIndicator()
                    : Assets.svg.iconFeedStory.icon(size: iconSize),
                label: context.i18n.feed_add_story,
                onPressed: isCapturing.value ? () {} : () => _onSharePostToStory(ref, isCapturing),
              ),
            ShareCopyLinkOption(
              shareUrl: shareUrl,
              userDisplayName: userDisplayName,
              content: content,
              iconSize: iconSize,
              imageUrl: imageUrl,
            ),
            ShareOptionsMenuItem(
              buttonType: ButtonType.dropdown,
              icon: Assets.svg.iconFeedWhatsapp.icon(size: iconSize),
              label: context.i18n.feed_whatsapp,
              onPressed: () {
                ref.read(socialShareServiceProvider).shareToWhatsApp(
                      shareUrl,
                      userDisplayName: userDisplayName,
                      content: content,
                      imageUrl: imageUrl,
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
                      userDisplayName: userDisplayName,
                      content: content,
                      imageUrl: imageUrl,
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
                      userDisplayName: userDisplayName,
                      content: content,
                      imageUrl: imageUrl,
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
                      userDisplayName: userDisplayName,
                      content: content,
                      imageUrl: imageUrl,
                    );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSharePostToStory(WidgetRef ref, ValueNotifier<bool> isCapturing) async {
    final context = ref.context;
    isCapturing.value = true;
    final postItselfEntity =
        ref.read(ionConnectEntityProvider(eventReference: eventReference)).valueOrNull;
    if (postItselfEntity == null || postItselfEntity is! ModifiablePostEntity) {
      isCapturing.value = false;
      return;
    }
    final parentContainer = ProviderScope.containerOf(context);
    final childContainer = ProviderContainer(
      parent: parentContainer,
    );

    try {
      final postWidget = UncontrolledProviderScope(
        container: childContainer,
        child: SharePostToStoryContent(
          eventReference: eventReference,
          postItselfEntity: postItselfEntity,
        ),
      );

      final tempFile = await captureWidgetScreenshot(context: context, widget: postWidget);
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

  (String? content, String? imageUrl) _getContentAndImageUrl(
    IonConnectEntity entity,
    UserMetadataEntity userMetadata,
  ) {
    switch (entity) {
      case ModifiablePostEntity():
        final content = entity.data.richText?.content ?? entity.data.textContent;
        String? imageUrl;
        if (!entity.isStory) {
          final firstMedia = entity.data.media.values.firstOrNull;
          imageUrl = firstMedia?.image ?? firstMedia?.url;
        }
        return (content, imageUrl);
      case ArticleEntity():
        return (entity.data.title, entity.data.image);
      case UserMetadataEntity():
        return (userMetadata.data.displayName, userMetadata.data.picture);
      case _:
        return (null, null);
    }
  }
}
