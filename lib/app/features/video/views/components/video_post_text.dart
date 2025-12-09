// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
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
import 'package:ion/app/features/feed/providers/parsed_media_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_media_content.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';

// As we cannot calculate the text size for Quill preview with textPainter because text can have different styles,
// Some width measurements deviation value is introduced here, which should work for the very majority of cases.
const _deviation = 30;
const _ellipsis = '\u2026';

class VideoTextPost extends HookConsumerWidget {
  const VideoTextPost({
    required this.entity,
    super.key,
  });

  final IonConnectEntity entity;

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

    final (:content, :media) = ref.watch(parsedMediaWithMentionsProvider(postData));
    if (content.isEmpty) return const SizedBox.shrink();
    final isTextExpanded = useState(false);
    final style = context.theme.appTextThemes.body2.copyWith(
      color: context.theme.appColors.secondaryBackground,
    );

    if (content.isBlank) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 10.0.s),
        LayoutBuilder(
          builder: (context, constraints) {
            final isOneLine = _isTextOneLine(
              text: Document.fromDelta(content).toPlainText(),
              style: style,
              maxWidth: constraints.maxWidth - _deviation.s,
            );

            final truncatedContent = isOneLine
                ? content
                : _truncateForOneLine(
                    content,
                    context.theme.appTextThemes.body2,
                    constraints.maxWidth - _deviation.s,
                    MediaQuery.textScalerOf(context),
                  );

            return GestureDetector(
              onTap: isOneLine ? null : () => isTextExpanded.value = !isTextExpanded.value,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SizeTransition(
                      sizeFactor: animation,
                      axisAlignment: -1,
                      child: child,
                    ),
                  );
                },
                child: TextEditorPreview(
                  key: ValueKey(isTextExpanded.value),
                  content: isTextExpanded.value ? content : truncatedContent,
                  maxHeight: !isOneLine && isTextExpanded.value ? 256.0.s : null,
                  scrollable: isTextExpanded.value,
                  customStyles: textEditorStyles(
                    context,
                    color: context.theme.appColors.secondaryBackground,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  bool _isTextOneLine({
    required String text,
    required TextStyle style,
    required double maxWidth,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    final didExceed = textPainter.didExceedMaxLines;
    textPainter.dispose();

    return !didExceed;
  }

  static Delta _truncateForOneLine(
    Delta content,
    TextStyle style,
    double maxWidth,
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
      ellipsis: _ellipsis,
      text: TextSpan(text: plainText, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      textScaler: textScaler,
    )..layout(maxWidth: maxWidth);

    // If text fits, return original
    if (!painter.didExceedMaxLines) {
      painter.dispose();

      return content;
    }

    // Find position at the end of the visible text region
    final yOffset = painter.height - 0.1;
    final textPosition = painter.getPositionForOffset(Offset(maxWidth, yOffset));
    final truncateOffset = textPosition.offset;
    painter.dispose();

    // Truncate content and add ellipsis at the end
    final truncated = QuillTextUtils.truncateDelta(content, truncateOffset);
    if (truncated.isNotEmpty) {
      final lastOp = truncated.operations.last;
      if (lastOp.data case final data? when data is String) {
        truncated.insert(data.endsWith('\n') ? _ellipsis : '$_ellipsis\n');
      }
    }

    return truncated;
  }
}
