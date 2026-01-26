// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/text_editor_preview.dart';
import 'package:ion/app/components/text_editor/utils/quill_text_utils.dart';
import 'package:ion/app/components/text_editor/utils/text_editor_styles.dart';
import 'package:ion/app/extensions/delta.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/providers/feed_posts_provider.r.dart';
import 'package:ion/app/features/feed/providers/parsed_media_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_media_content.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';

class PostContent extends HookConsumerWidget {
  const PostContent({
    required this.entity,
    this.content,
    this.accentTheme = false,
    this.isTextSelectable = false,
    this.maxLines = 4,
    this.plainInlineStyles = false,
    super.key,
  });

  final bool accentTheme;
  final IonConnectEntity entity;
  final bool isTextSelectable;
  final int? maxLines;
  final Delta? content;
  final bool plainInlineStyles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentContent = content ?? _getContent(ref);

    if (currentContent == null || currentContent.isBlank) {
      return const SizedBox.shrink();
    }

    final isExpanded = ref.watch(expandedPostsStateProvider).contains(entity.id);

    return LayoutBuilder(
      builder: (context, constraints) => _PostContentWithCache(
        content: currentContent,
        entity: entity,
        isExpanded: isExpanded,
        maxLines: maxLines,
        maxWidth: constraints.maxWidth,
        accentTheme: accentTheme,
        isTextSelectable: isTextSelectable,
        plainInlineStyles: plainInlineStyles,
      ),
    );
  }

  Delta? _getContent(WidgetRef ref) {
    final postData = switch (entity) {
      final ModifiablePostEntity post => post.data,
      final PostEntity post => post.data,
      _ => null,
    };

    if (postData is! EntityDataWithMediaContent) {
      return null;
    }

    final result = ref.watch(parsedMediaWithMentionsProvider(postData));
    return result.content;
  }
}

class _TruncationResult {
  _TruncationResult({required this.delta, required this.hasOverflow});

  final Delta delta;
  final bool hasOverflow;
}

class _PostContentWithCache extends HookConsumerWidget {
  const _PostContentWithCache({
    required this.content,
    required this.entity,
    required this.isExpanded,
    required this.maxLines,
    required this.maxWidth,
    required this.accentTheme,
    required this.isTextSelectable,
    required this.plainInlineStyles,
  });

  final Delta content;
  final IonConnectEntity entity;
  final bool isExpanded;
  final int? maxLines;
  final double maxWidth;
  final bool accentTheme;
  final bool isTextSelectable;
  final bool plainInlineStyles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Cache the truncation result using useMemoized
    final truncResult = useMemoized(
      () {
        if (maxLines != null && !isExpanded) {
          return _truncateForMaxLines(
            content,
            context.theme.appTextThemes.body2,
            maxWidth,
            maxLines!,
            MediaQuery.textScalerOf(context),
          );
        }
        return _TruncationResult(delta: content, hasOverflow: false);
      },
      [content, maxWidth, maxLines, isExpanded],
    );

    final hasOverflow = truncResult.hasOverflow;
    final displayDelta = hasOverflow ? truncResult.delta : content;

    return AnimatedSize(
      duration: 300.ms,
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextEditorPreview(
            key: ValueKey(isExpanded),
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
            ignoreInlineBoldItalic: plainInlineStyles,
          ),
          if (hasOverflow && maxLines != null)
            GestureDetector(
              onTap: () => ref.read(expandedPostsStateProvider.notifier).expand(entity),
              child: Padding(
                padding: EdgeInsetsDirectional.only(top: 4.0.s),
                child: Text(
                  context.i18n.common_show_more,
                  style: context.theme.appTextThemes.body2.copyWith(
                    color: accentTheme
                        ? context.theme.appColors.onPrimaryAccent
                        : context.theme.appColors.primaryAccent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  _TruncationResult _truncateForMaxLines(
    Delta content,
    TextStyle style,
    double maxWidth,
    int maxLines,
    TextScaler textScaler,
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
      textScaler: textScaler,
    )..layout(maxWidth: maxWidth);

    // If text fits, return original
    if (!painter.didExceedMaxLines) {
      painter.dispose();

      return _TruncationResult(delta: content, hasOverflow: false);
    }

    // Find position at the end of the visible text region
    final yOffset = painter.height - 0.1;
    final textPosition = painter.getPositionForOffset(Offset(maxWidth, yOffset));
    final truncateOffset = textPosition.offset;
    painter.dispose();

    // Truncate content and ensure newline at end
    final truncated = QuillTextUtils.truncateDelta(content, truncateOffset);
    if (truncated.isNotEmpty) {
      final lastOp = truncated.operations.last;
      if (lastOp.data case final data? when data is String && !data.endsWith('\n')) {
        truncated.insert('\n');
      }
    }

    return _TruncationResult(delta: truncated, hasOverflow: true);
  }
}
