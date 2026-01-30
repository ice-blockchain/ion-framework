// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/cashtag/text_editor_cashtag_embed_builder.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/text_editor_mention_embed_builder.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/text_editor_code_block/text_editor_code_block.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/text_editor_separator_block/text_editor_separator_block.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/text_editor_single_image_block/text_editor_single_image_block.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/unknown/text_editor_unknown_embed_builder.dart';
import 'package:ion/app/components/text_editor/custom_recognizer_builder.dart';
import 'package:ion/app/components/text_editor/hooks/use_process_cashtag_embeds.dart';
import 'package:ion/app/components/text_editor/hooks/use_process_mention_embeds.dart';
import 'package:ion/app/components/text_editor/utils/delta_bridge.dart';
import 'package:ion/app/components/text_editor/utils/text_editor_styles.dart';
import 'package:ion/app/extensions/delta.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/services/browser/browser.dart';

class TextEditorPreview extends HookWidget {
  const TextEditorPreview({
    required this.content,
    this.enableInteractiveSelection = false,
    this.media,
    this.maxHeight,
    this.customStyles,
    this.tagsColor,
    this.scrollable = true,
    this.authorPubkey,
    this.eventReference,
    this.ignoreInlineBoldItalic = false,
    this.convertMentionsToEmbeds = true,
    super.key,
  });

  final Delta content;
  final bool enableInteractiveSelection;
  final Map<String, MediaAttachment>? media;
  final DefaultStyles? customStyles;
  final double? maxHeight;
  final bool scrollable;
  final Color? tagsColor;
  final String? authorPubkey;
  final String? eventReference;
  final bool ignoreInlineBoldItalic;
  final bool convertMentionsToEmbeds;

  @override
  Widget build(BuildContext context) {
    // Convert mention attributes to embeds for display in view mode (only for posts/articles, not replies)
    final contentWithEmbeds = useMemoized(
      () {
        if (convertMentionsToEmbeds) {
          return DeltaBridge.normalizeToEmbedFormat(content);
        }

        // For replies: keep as text (will be decorated with market cap if available)
        return content;
      },
      [content, convertMentionsToEmbeds],
    );

    final controller = useMemoized(
      () => QuillController(
        document: Document.fromDelta(contentWithEmbeds),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      ),
      [contentWithEmbeds],
    );

    if (contentWithEmbeds.isBlank) {
      return const SizedBox.shrink();
    }

    return _QuillFormattedContent(
      tagsColor: tagsColor,
      controller: controller,
      convertMentionsToEmbeds: convertMentionsToEmbeds,
      customStyles: customStyles,
      media: media,
      maxHeight: maxHeight,
      scrollable: scrollable,
      enableInteractiveSelection: enableInteractiveSelection,
      authorPubkey: authorPubkey,
      eventReference: eventReference,
      ignoreInlineBoldItalic: ignoreInlineBoldItalic,
    );
  }
}

class _QuillFormattedContent extends HookConsumerWidget {
  const _QuillFormattedContent({
    required this.controller,
    required this.enableInteractiveSelection,
    required this.convertMentionsToEmbeds,
    this.customStyles,
    this.media,
    this.maxHeight,
    this.tagsColor,
    this.scrollable = true,
    this.authorPubkey,
    this.eventReference,
    this.ignoreInlineBoldItalic = false,
  });

  final QuillController controller;
  final bool enableInteractiveSelection;
  final bool convertMentionsToEmbeds;
  final DefaultStyles? customStyles;
  final Map<String, MediaAttachment>? media;
  final double? maxHeight;
  final bool scrollable;
  final Color? tagsColor;
  final String? authorPubkey;
  final String? eventReference;
  final bool ignoreInlineBoldItalic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use reactive hook to process mention embeds bidirectionally (same as edit mode).
    // Downgrades embeds without market cap to text, upgrades text mentions when market cap appears.
    // Only enabled when mentions are rendered as embeds (posts/articles). For replies, mentions stay as text.
    useProcessMentionEmbeds(
      controller,
      ref,
      enabled: convertMentionsToEmbeds,
    );

    useProcessCashtagEmbeds(
      controller,
      ref,
      enabled: convertMentionsToEmbeds,
    );

    final effectiveStyles = useMemoized(
      () {
        if (ignoreInlineBoldItalic) {
          final color = customStyles?.paragraph?.style.color;
          return textEditorStylesPlainInline(context, color: color);
        }

        return customStyles ?? textEditorStyles(context);
      },
      [ignoreInlineBoldItalic, customStyles],
    );

    return QuillEditor.basic(
      controller: controller,
      config: QuillEditorConfig(
        onLaunchUrl: (url) => openDeepLinkOrInAppBrowser(url, ref),
        floatingCursorDisabled: true,
        showCursor: false,
        scrollable: scrollable,
        enableInteractiveSelection: enableInteractiveSelection,
        customStyles: effectiveStyles,
        maxHeight: maxHeight,
        embedBuilders: [
          TextEditorSingleImageBuilder(
            media: media,
            authorPubkey: authorPubkey,
            eventReference: eventReference,
          ),
          TextEditorSeparatorBuilder(readOnly: true),
          TextEditorCodeBuilder(readOnly: true),
          if (convertMentionsToEmbeds) const TextEditorMentionEmbedBuilder(showClose: false),
          if (convertMentionsToEmbeds) const TextEditorCashtagEmbedBuilder(showClose: false),
        ],
        unknownEmbedBuilder: TextEditorUnknownEmbedBuilder(),
        disableClipboard: true,
        customStyleBuilder: (attribute) =>
            customTextStyleBuilder(attribute, context, tagsColor: tagsColor),
        customRecognizerBuilder: (attribute, leaf) => customRecognizerBuilder(
          context,
          attribute,
        ),
      ),
    );
  }
}
