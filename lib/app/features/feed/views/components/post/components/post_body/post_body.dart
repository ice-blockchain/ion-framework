// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/utils/is_attributed_operation.dart';
import 'package:ion/app/components/url_preview/providers/url_metadata_provider.r.dart';
import 'package:ion/app/extensions/delta.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/polls/models/poll_data.f.dart';
import 'package:ion/app/features/feed/polls/view/components/post_poll.dart';
import 'package:ion/app/features/feed/providers/parsed_media_provider.r.dart';
import 'package:ion/app/features/feed/views/components/post/components/post_body/components/post_media/post_media.dart';
import 'package:ion/app/features/feed/views/components/post/components/post_body/post_content.dart';
import 'package:ion/app/features/feed/views/components/url_preview_content/url_preview_content.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_media_content.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/typedefs/typedefs.dart';
import 'package:ion/app/utils/url.dart';

class PostBody extends HookConsumerWidget {
  const PostBody({
    required this.entity,
    this.accentTheme = false,
    this.isTextSelectable = false,
    this.maxLines = 6,
    this.onVideoTap,
    this.sidePadding,
    this.framedEventReference,
    this.videoAutoplay = true,
    super.key,
  });

  final bool accentTheme;
  final IonConnectEntity entity;
  final bool isTextSelectable;
  final EventReference? framedEventReference;
  final int? maxLines;
  final double? sidePadding;
  final OnVideoTapCallback? onVideoTap;
  final bool videoAutoplay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postData = switch (entity) {
      final ModifiablePostEntity post => post.data,
      final PostEntity post => post.data,
      _ => null,
    };

    if (postData is! EntityDataWithMediaContent) {
      return const SizedBox.shrink();
    }

    final (:content, :media) = ref.watch(cachedParsedMediaProvider(postData));

    final firstUrlInPost = useMemoized(
      () {
        final firstOperationLink = content.operations
            .firstWhereOrNull(
              (operation) => isAttributedOperation(operation, attribute: Attribute.link),
            )
            ?.value as String?;

        return firstOperationLink == null ? null : normalizeUrl(firstOperationLink);
      },
      [content],
    );

    final hasValidUrlMetadata = firstUrlInPost != null &&
        (ref.watch(urlMetadataProvider(firstUrlInPost)).valueOrNull?.title?.isNotEmpty ?? false);
        
    final showTextContent = useMemoized(
      () {
        if (content.isBlank) {
          return false;
        }

        if (content.isSingleLinkOnly && hasValidUrlMetadata && media.isEmpty) {
          return false;
        }
        return true;
      },
      [content, hasValidUrlMetadata, media],
    );

    // Extract poll data from post
    final pollData = _getPollData(postData);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10.0.s,
      children: [
        if (showTextContent || pollData != null)
          Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: sidePadding ?? 16.0.s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showTextContent)
                  PostContent(
                    content: content,
                    entity: entity,
                    accentTheme: accentTheme,
                    isTextSelectable: isTextSelectable,
                    maxLines: maxLines,
                  ),
                if (pollData != null)
                  PostPoll(
                    pollData: pollData,
                    accentTheme: accentTheme,
                    postReference: entity.toEventReference(),
                  ),
              ],
            ),
          ),
        if (media.isNotEmpty)
          PostMedia(
            media: media,
            onVideoTap: onVideoTap,
            sidePadding: sidePadding,
            videoAutoplay: videoAutoplay,
            eventReference: entity.toEventReference(),
            framedEventReference: framedEventReference,
          ),
        if (media.isEmpty && hasValidUrlMetadata)
          Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: sidePadding ?? 16.0.s),
            child: UrlPreviewContent(
              url: firstUrlInPost!,
            ),
          ),
      ],
    );
  }

  PollData? _getPollData(dynamic postData) {
    if (postData is ModifiablePostData) {
      return postData.poll;
    }
    return null;
  }
}
