// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_quill/flutter_quill.dart';

class QuillStyleManager {
  QuillStyleManager(this._controller);
  final QuillController _controller;

  // Store preserved styles per block start position
  static Map<int, List<_StyleRange>>? _preservedStylesByBlock;

  void dispose() {
    // Clear all preserved styles since we can't distinguish between controllers
    _preservedStylesByBlock?.clear();
    _preservedStylesByBlock = null;
  }

  void toggleHeaderStyle(Attribute<dynamic> headerAttribute) {
    final currentStyle = _controller.getSelectionStyle();

    final isSameHeaderStyle =
        currentStyle.attributes[headerAttribute.key]?.value == headerAttribute.value;

    // Find the line/block containing the cursor
    final docPlainText = _controller.document.toPlainText();
    final cursorPos = _controller.selection.baseOffset;

    // Find block boundaries
    final textBeforeCursor = docPlainText.substring(0, cursorPos);
    final lastNewlineBefore = textBeforeCursor.lastIndexOf('\n');
    final blockStart = lastNewlineBefore >= 0 ? lastNewlineBefore + 1 : 0;

    final textAfterCursor = docPlainText.substring(cursorPos);
    final firstNewlineAfter = textAfterCursor.indexOf('\n');
    final blockEnd =
        firstNewlineAfter >= 0 ? cursorPos + firstNewlineAfter + 1 : docPlainText.length;

    final blockLength = blockEnd - blockStart;

    if (!isSameHeaderStyle) {
      // Applying header: preserve styles first, then wipe them
      // Check if we already have preserved styles (e.g., when switching between headers)
      List<_StyleRange> preservedStyles = _getPreservedStyles(blockStart, remove: false);

      if (preservedStyles.isEmpty && blockLength > 0) {
        // No preserved styles, try to extract from document
        final extractedStyles = _extractInlineStyles(blockStart, blockLength);
        if (extractedStyles.isNotEmpty) {
          preservedStyles = extractedStyles;
          _storePreservedStyles(blockStart, preservedStyles);
        }
      }

      // Wipe inline styles from the entire block
      if (blockLength > 0) {
        _controller
          ..formatText(blockStart, blockLength, Attribute.clone(Attribute.bold, null))
          ..formatText(blockStart, blockLength, Attribute.clone(Attribute.italic, null))
          ..formatText(blockStart, blockLength, Attribute.clone(Attribute.underline, null))
          ..formatText(blockStart, blockLength, Attribute.clone(Attribute.link, null));
      }

      // Wipe header styles
      wipeAllStyles();

      // Apply header
      _controller.formatSelection(headerAttribute);
    } else {
      // Removing header: restore preserved styles, then remove header
      // Don't remove from map - keep them for the next toggle
      final preservedStyles = _getPreservedStyles(blockStart, remove: false);

      // Wipe header styles first
      wipeAllStyles();

      // Remove header
      _controller.formatSelection(Attribute.clone(headerAttribute, null));

      // Restore preserved inline styles
      if (preservedStyles.isNotEmpty) {
        _restoreInlineStyles(preservedStyles, blockStart);

        // Verify styles were restored by checking document
        final verifyStyles = _extractInlineStyles(blockStart, blockLength);

        // Update stored styles with verified styles (if available) to ensure accuracy
        // Don't remove from map - keep them for future toggles
        if (verifyStyles.isNotEmpty) {
          _storePreservedStyles(blockStart, verifyStyles);
        }
      }
    }
  }

  /// Extracts inline style ranges from the document for a given block range
  List<_StyleRange> _extractInlineStyles(int blockStart, int blockLength) {
    final styles = <_StyleRange>[];
    final deltaOps = _controller.document.toDelta().toList();
    var currentOffset = 0;
    final blockEnd = blockStart + blockLength;

    for (final op in deltaOps) {
      final opLength = op.data is String ? (op.data as String).length : 1;
      final opStart = currentOffset;
      final opEnd = currentOffset + opLength;

      // Check if this operation overlaps with our block
      if (opStart < blockEnd && opEnd > blockStart) {
        final rangeStart = opStart > blockStart ? opStart : blockStart;
        final rangeEnd = opEnd < blockEnd ? opEnd : blockEnd;
        final rangeLength = rangeEnd - rangeStart;

        if (rangeLength > 0 && op.attributes != null) {
          final attrs = op.attributes!;

          // Extract inline styles (not block-level)
          if (attrs.containsKey(Attribute.bold.key)) {
            styles.add((
              start: rangeStart - blockStart,
              length: rangeLength,
              attribute: Attribute.bold,
            ));
          }
          if (attrs.containsKey(Attribute.italic.key)) {
            styles.add((
              start: rangeStart - blockStart,
              length: rangeLength,
              attribute: Attribute.italic,
            ));
          }
          if (attrs.containsKey(Attribute.underline.key)) {
            styles.add((
              start: rangeStart - blockStart,
              length: rangeLength,
              attribute: Attribute.underline,
            ));
          }
        }
      }

      currentOffset = opEnd;
      if (currentOffset >= blockEnd) break;
    }

    return styles;
  }

  /// Stores preserved styles for a block
  void _storePreservedStyles(int blockStart, List<_StyleRange> styles) {
    _preservedStylesByBlock ??= <int, List<_StyleRange>>{};
    _preservedStylesByBlock![blockStart] = List.from(styles); // Store a copy
  }

  /// Gets preserved styles for a block (never removes from map)
  List<_StyleRange> _getPreservedStyles(int blockStart, {bool remove = false}) {
    final styles = _preservedStylesByBlock?[blockStart] ?? [];
    return List.from(styles); // Return a copy to prevent external modification
  }

  /// Clears preserved styles for a block (called when user explicitly changes styles)
  void _clearPreservedStyles(int blockStart) {
    _preservedStylesByBlock?.remove(blockStart);
  }

  /// Restores inline styles to the block
  void _restoreInlineStyles(List<_StyleRange> styles, int blockStart) {
    for (final styleRange in styles) {
      _controller.formatText(
        blockStart + styleRange.start,
        styleRange.length,
        styleRange.attribute,
      );
    }
  }

  void toggleTextStyle(Attribute<dynamic> textAttribute) {
    final currentStyle = _controller.getSelectionStyle();

    // Find the block containing the cursor
    final docPlainText = _controller.document.toPlainText();
    final cursorPos = _controller.selection.baseOffset;
    final selectionLength =
        (_controller.selection.extentOffset - _controller.selection.baseOffset).abs();
    final textBeforeCursor = docPlainText.substring(0, cursorPos);
    final lastNewlineBefore = textBeforeCursor.lastIndexOf('\n');
    final blockStart = lastNewlineBefore >= 0 ? lastNewlineBefore + 1 : 0;
    final textAfterCursor = docPlainText.substring(cursorPos);
    final firstNewlineAfter = textAfterCursor.indexOf('\n');
    final blockEnd =
        firstNewlineAfter >= 0 ? cursorPos + firstNewlineAfter + 1 : docPlainText.length;
    final blockLength = blockEnd - blockStart;

    final mutuallyExclusiveStyles = [Attribute.bold.key, Attribute.italic.key];

    final hasHeaderOrLink = currentStyle.attributes.keys.any(
      (key) => [Attribute.header.key, Attribute.link.key].contains(key),
    );

    if (hasHeaderOrLink) {
      // Get selection range relative to block start
      final selectionStart = cursorPos - blockStart;
      final selectionEnd = selectionStart + selectionLength;

      wipeAllStyles(retainStyles: {Attribute.underline.key});

      _controller.formatSelection(textAttribute);

      // User changed styles while in header - merge preserved styles with newly extracted styles
      if (blockLength > 0) {
        final extractedStyles = _extractInlineStyles(blockStart, blockLength);
        final preservedStyles = _getPreservedStyles(blockStart, remove: false);

        // Merge preserved styles with extracted styles
        // Strategy: Use extracted styles as source of truth (they reflect current document state)
        // But preserve non-overlapping parts of preserved styles
        final mergedStyles = <_StyleRange>[];

        // First, add all extracted styles (they reflect the current document state after user's change)
        mergedStyles.addAll(extractedStyles);

        // Then, add preserved styles that don't overlap with the selection
        // These represent styles that were outside the selection and weren't affected
        for (final preserved in preservedStyles) {
          final preservedEnd = preserved.start + preserved.length;

          // If preserved style doesn't overlap with selection, add it
          if (preservedEnd <= selectionStart || preserved.start >= selectionEnd) {
            // Check if we already have this exact style in merged
            final alreadyExists = mergedStyles.any((existing) {
              return existing.attribute.key == preserved.attribute.key &&
                  existing.start == preserved.start &&
                  existing.length == preserved.length;
            });

            if (!alreadyExists) {
              mergedStyles.add(preserved);
            }
          }
          // If preserved style overlaps with selection, we don't add it
          // because the extracted styles already represent the current state in that range
        }

        if (mergedStyles.isNotEmpty) {
          _storePreservedStyles(blockStart, mergedStyles);

          // Restore all preserved styles to the document so they're visible
          // (When header is active, inline styles aren't visible, but we need to keep them in the document)
          _restoreInlineStyles(mergedStyles, blockStart);
        } else {
          _clearPreservedStyles(blockStart);
        }
      }
      return;
    }

    if (mutuallyExclusiveStyles.contains(textAttribute.key)) {
      toggleRegularStyle();
      for (final key in mutuallyExclusiveStyles) {
        if (currentStyle.attributes.containsKey(key) && key != textAttribute.key) {
          final attribute = Attribute.fromKeyValue(key, null);
          if (attribute != null) {
            _controller.formatSelection(Attribute.clone(attribute, null));
          }
        }
      }
    }

    if (currentStyle.attributes.containsKey(textAttribute.key)) {
      _controller.formatSelection(Attribute.clone(textAttribute, null));
    } else {
      _controller.formatSelection(textAttribute);
    }

    // User explicitly changed inline styles (not in header) - clear preserved styles
    _clearPreservedStyles(blockStart);
  }

  void toggleLinkStyle(String? link) {
    if (link == null || link.isEmpty) {
      wipeAllStyles();
      _controller.formatSelection(const LinkAttribute(null));
    } else {
      wipeAllStyles(retainStyles: {Attribute.link.key});
      _controller.formatSelection(LinkAttribute(link));
    }
  }

  void toggleRegularStyle() {
    _controller
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
        _controller.formatSelection(Attribute.clone(attribute, null));
      }
    }
  }
}

/// Represents a style range within a block
typedef _StyleRange = ({
  int start,
  int length,
  Attribute<dynamic> attribute,
});
