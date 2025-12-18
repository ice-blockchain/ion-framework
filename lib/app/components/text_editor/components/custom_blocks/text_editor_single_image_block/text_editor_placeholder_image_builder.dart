// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/text_editor_single_image_block/text_editor_single_image_block.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';

/// A lightweight embed builder that renders placeholder boxes instead of actual images.
/// Used for offscreen height measurement to avoid expensive image loading.
class TextEditorPlaceholderImageBuilder extends EmbedBuilder {
  TextEditorPlaceholderImageBuilder({this.media});

  final Map<String, MediaAttachment>? media;

  static const double _defaultAspectRatio = 16 / 9;

  @override
  String get key => textEditorSingleImageKey;

  @override
  Widget build(
    BuildContext context,
    EmbedContext embedContext,
  ) {
    final path = embedContext.node.value.data as String;
    final attachment = media?[path];
    final aspectRatio = attachment?.aspectRatio ?? _defaultAspectRatio;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0.s),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }
}
