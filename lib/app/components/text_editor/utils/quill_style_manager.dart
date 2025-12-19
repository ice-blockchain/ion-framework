// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_quill/flutter_quill.dart';

class QuillStyleManager {
  QuillStyleManager(this.controller);
  final QuillController controller;

  void toggleHeaderStyle(Attribute<dynamic> headerAttribute) {
    final currentStyle = controller.getSelectionStyle();
    final docPlainText = controller.document.toPlainText();
    final docLength = controller.document.length;

    final isSameHeaderStyle =
        currentStyle.attributes[headerAttribute.key]?.value == headerAttribute.value;

    // Find the line/block containing the cursor
    // Headers in Quill are block-level attributes that apply to entire lines
    final cursorPos = controller.selection.baseOffset;
    var blockStart = 0;
    var blockEnd = docLength;

    // Find the start of the line (previous newline or start of doc)
    final textBeforeCursor = docPlainText.substring(0, cursorPos);
    final lastNewlineBefore = textBeforeCursor.lastIndexOf('\n');
    if (lastNewlineBefore >= 0) {
      blockStart = lastNewlineBefore + 1;
    } else {
      blockStart = 0;
    }

    // Find the end of the line (next newline or end of doc)
    final textAfterCursor = docPlainText.substring(cursorPos);
    final firstNewlineAfter = textAfterCursor.indexOf('\n');
    if (firstNewlineAfter >= 0) {
      blockEnd = cursorPos + firstNewlineAfter + 1; // Include the newline
    } else {
      blockEnd = docLength;
    }

    // Wipe all styles from the entire block range first
    final blockLength = blockEnd - blockStart;
    if (blockLength > 0) {
      // Wipe inline styles from the entire block using formatText
      controller
        ..formatText(blockStart, blockLength, Attribute.clone(Attribute.bold, null))
        ..formatText(blockStart, blockLength, Attribute.clone(Attribute.italic, null))
        ..formatText(blockStart, blockLength, Attribute.clone(Attribute.underline, null))
        ..formatText(blockStart, blockLength, Attribute.clone(Attribute.link, null));
    }

    // Wipe header styles (these are block-level, so formatSelection should work)
    wipeAllStyles();

    if (!isSameHeaderStyle) {
      // Apply header to the entire block using formatText
      if (blockLength > 0) {
        controller.formatText(blockStart, blockLength, headerAttribute);
      } else {
        // Fallback to formatSelection
        controller.formatSelection(headerAttribute);
      }
    }
  }

  void toggleTextStyle(Attribute<dynamic> textAttribute) {
    final currentStyle = controller.getSelectionStyle();

    final mutuallyExclusiveStyles = [Attribute.bold.key, Attribute.italic.key];

    final hasHeaderOrLink = currentStyle.attributes.keys.any(
      (key) => ['h1', 'h2', 'h3', Attribute.link.key].contains(key),
    );

    if (hasHeaderOrLink) {
      wipeAllStyles(retainStyles: {Attribute.underline.key});
      controller.formatSelection(textAttribute);
      return;
    }

    if (mutuallyExclusiveStyles.contains(textAttribute.key)) {
      toggleRegularStyle();
      for (final key in mutuallyExclusiveStyles) {
        if (currentStyle.attributes.containsKey(key) && key != textAttribute.key) {
          final attribute = Attribute.fromKeyValue(key, null);
          if (attribute != null) {
            controller.formatSelection(Attribute.clone(attribute, null));
          }
        }
      }
    }

    if (currentStyle.attributes.containsKey(textAttribute.key)) {
      controller.formatSelection(Attribute.clone(textAttribute, null));
    } else {
      controller.formatSelection(textAttribute);
    }
  }

  void toggleLinkStyle(String? link) {
    if (link == null || link.isEmpty) {
      wipeAllStyles();
      controller.formatSelection(const LinkAttribute(null));
    } else {
      wipeAllStyles(retainStyles: {Attribute.link.key});
      controller.formatSelection(LinkAttribute(link));
    }
  }

  void toggleRegularStyle() {
    controller
      ..formatSelection(Attribute.clone(Attribute.h1, null))
      ..formatSelection(Attribute.clone(Attribute.h2, null))
      ..formatSelection(Attribute.clone(Attribute.h3, null));
  }

  void wipeAllStyles({Set<String> retainStyles = const {}}) {
    final allStyles = {
      Attribute.bold.key: Attribute.bold,
      Attribute.italic.key: Attribute.italic,
      Attribute.underline.key: Attribute.underline,
      Attribute.link.key: Attribute.link,
      Attribute.h1.key: Attribute.h1,
      Attribute.h2.key: Attribute.h2,
      Attribute.h3.key: Attribute.h3,
    };

    for (final entry in allStyles.entries) {
      if (!retainStyles.contains(entry.key)) {
        final attribute = entry.value as Attribute<dynamic>;
        controller.formatSelection(Attribute.clone(attribute, null));
      }
    }
  }
}
