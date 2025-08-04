// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/text_editor_preview.dart';
import 'package:ion/app/components/text_editor/utils/is_attributed_operation.dart';
import 'package:ion/app/components/text_editor/utils/text_editor_styles.dart';
import 'package:ion/app/components/url_preview/providers/url_metadata_provider.r.dart';
import 'package:ion/app/extensions/delta.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/polls/models/poll_data.f.dart';
import 'package:ion/app/features/feed/polls/view/components/post_poll.dart';
import 'package:ion/app/features/feed/views/components/post/components/post_body/components/post_media/post_media.dart';
import 'package:ion/app/features/feed/views/components/url_preview_content/url_preview_content.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_media_content.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/views/hooks/use_parsed_media_content.dart';
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

    final (:content, :media) = useParsedMediaContent(
      data: postData,
      key: ValueKey(postData.hashCode),
    );

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

    final hasValidUrlMetadata = useMemoized(
      () =>
          firstUrlInPost != null &&
          (ref.watch(urlMetadataProvider(firstUrlInPost)).valueOrNull?.title?.isNotEmpty ?? false),
      [firstUrlInPost],
    );

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final truncResult = maxLines != null
            ? _truncateForMaxLines(
                content,
                context.theme.appTextThemes.body2,
                constraints.maxWidth,
                maxLines!,
              )
            : _TruncationResult(delta: content, hasOverflow: false);
        final displayDelta = truncResult.delta;
        final hasOverflow = truncResult.hasOverflow;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10.0.s,
          children: [
            if (showTextContent || hasOverflow || pollData != null)
              Padding(
                padding: EdgeInsetsDirectional.symmetric(horizontal: sidePadding ?? 16.0.s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showTextContent)
                      TextEditorPreview(
                        scrollable: false,
                        content: displayDelta,
                        customStyles: accentTheme
                            ? textEditorStyles(
                                context,
                                color: context.theme.appColors.onPrimaryAccent,
                              )
                            : null,
                        enableInteractiveSelection: isTextSelectable,
                        tagsColor: accentTheme ? context.theme.appColors.anakiwa : null,
                      ),
                    if (hasOverflow)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          context.i18n.common_show_more,
                          style: context.theme.appTextThemes.body2.copyWith(
                            color: accentTheme
                                ? context.theme.appColors.primaryBackground
                                : context.theme.appColors.darkBlue,
                          ),
                        ),
                      ),
                    if (pollData != null)
                      PostPoll(
                        pollData: pollData,
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
      },
    );
  }

  PollData? _getPollData(dynamic postData) {
    if (postData is ModifiablePostData) {
      return postData.poll;
    }
    return null;
  }

  Delta _truncateDelta(Delta original, int maxChars) {
    final truncated = Delta();
    var consumed = 0;
    for (final op in original.toList()) {
      final data = op.data;
      if (data is String) {
        if (consumed >= maxChars) break;
        final remaining = maxChars - consumed;
        if (data.length <= remaining) {
          truncated.push(op);
          consumed += data.length;
        } else {
          truncated.insert(data.substring(0, remaining), op.attributes);
          break;
        }
      } else {
        // preserve embeds until overflow
        if (consumed < maxChars) {
          truncated.push(op);
        }
      }
    }
    return truncated;
  }

  _TruncationResult _truncateForMaxLines(
    Delta content,
    TextStyle style,
    double maxWidth,
    int maxLines,
  ) {
    // Ensure content ends with a newline for proper measurement
    final contentForLayout = content;
    if (contentForLayout.isNotEmpty) {
      final lastOp = contentForLayout.operations.last;
      if (lastOp.data is String && !(lastOp.data! as String).endsWith('\n')) {
        contentForLayout.insert('\n');
      }
    }

    final plainText = Document.fromDelta(contentForLayout).toPlainText();
    final painter = TextPainter(
      text: TextSpan(text: plainText, style: style),
      textDirection: TextDirection.ltr,
      maxLines: maxLines - 1,
    )..layout(maxWidth: maxWidth);

    // If text fits, return original
    if (!painter.didExceedMaxLines) {
      return _TruncationResult(delta: content, hasOverflow: false);
    }

    // Find position at the end of the visible text region
    final yOffset = painter.height - 0.1;
    final textPosition = painter.getPositionForOffset(Offset(maxWidth, yOffset));
    final truncateOffset = textPosition.offset;

    // Truncate content and ensure newline at end
    final truncated = _truncateDelta(content, truncateOffset);
    if (truncated.isNotEmpty) {
      final lastOp = truncated.operations.last;
      if (lastOp.data is String && !(lastOp.data! as String).endsWith('\n')) {
        truncated.insert('\n');
      }
    }

    return _TruncationResult(delta: truncated, hasOverflow: true);
  }
}

class _TruncationResult {
  _TruncationResult({required this.delta, required this.hasOverflow});

  final Delta delta;
  final bool hasOverflow;
}
