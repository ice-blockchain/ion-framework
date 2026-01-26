// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:ion_ads/ion_ads.dart';

const textEditorAdKey = 'text-editor-ad';

///
/// Embeds a ad block in the text editor.
///
class TextEditorAdEmbed extends CustomBlockEmbed {
  TextEditorAdEmbed() : super(textEditorAdKey, '---');

  static BlockEmbed adBlock() => TextEditorAdEmbed();
}

///
/// Embed builder for [TextEditorAdEmbed].
///
class TextEditorAdBuilder extends EmbedBuilder {
  TextEditorAdBuilder();

  @override
  String get key => textEditorAdKey;

  @override
  Widget build(
    BuildContext context,
    EmbedContext embedContext,
  ) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280, minHeight: 266),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: AppodealNativeAd(
          options: NativeAdOptions.customOptions(nativeAdType: NativeAdType.article),
        ),
      ),
    );
  }
}
