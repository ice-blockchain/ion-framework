// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_quill/flutter_quill.dart';

class QuillStyleManager {
  QuillStyleManager(this._controller);
  final QuillController _controller;

  static Map<int, List<_StyleRange>>? _preservedStylesByBlock;

  void dispose() {
    _preservedStylesByBlock?.clear();
    _preservedStylesByBlock = null;
  }

  void toggleHeaderStyle(Attribute<dynamic> headerAttribute) {
    final currentStyle = _controller.getSelectionStyle();
    final isSameHeaderStyle =
        currentStyle.attributes[headerAttribute.key]?.value == headerAttribute.value;

    final (blockStart, blockLength) = _getBlockRange();

    if (!isSameHeaderStyle) {
      var preservedStyles = _getPreservedStyles(blockStart);

      if (preservedStyles.isEmpty && blockLength > 0) {
        final extractedStyles = _extractInlineStyles(blockStart, blockLength);
        if (extractedStyles.isNotEmpty) {
          preservedStyles = extractedStyles;
          _storePreservedStyles(blockStart, preservedStyles);
        }
      }

      if (blockLength > 0) {
        _controller
          ..formatText(blockStart, blockLength, Attribute.clone(Attribute.bold, null))
          ..formatText(blockStart, blockLength, Attribute.clone(Attribute.italic, null))
          ..formatText(blockStart, blockLength, Attribute.clone(Attribute.underline, null))
          ..formatText(blockStart, blockLength, Attribute.clone(Attribute.link, null));
      }

      wipeAllStyles();
      _controller.formatSelection(headerAttribute);
    } else {
      final preservedStyles = _getPreservedStyles(blockStart);

      wipeAllStyles();
      _controller.formatSelection(Attribute.clone(headerAttribute, null));

      if (preservedStyles.isNotEmpty) {
        _restoreInlineStyles(preservedStyles, blockStart);
        final verifyStyles = _extractInlineStyles(blockStart, blockLength);
        if (verifyStyles.isNotEmpty) {
          _storePreservedStyles(blockStart, verifyStyles);
        }
      }
    }
  }

  (int blockStart, int blockLength) _getBlockRange() {
    final docPlainText = _controller.document.toPlainText();
    final cursorPos = _controller.selection.baseOffset;
    final textBeforeCursor = docPlainText.substring(0, cursorPos);
    final lastNewlineBefore = textBeforeCursor.lastIndexOf('\n');
    final blockStart = lastNewlineBefore >= 0 ? lastNewlineBefore + 1 : 0;
    final textAfterCursor = docPlainText.substring(cursorPos);
    final firstNewlineAfter = textAfterCursor.indexOf('\n');
    final blockEnd =
        firstNewlineAfter >= 0 ? cursorPos + firstNewlineAfter + 1 : docPlainText.length;
    final blockLength = blockEnd - blockStart;
    return (blockStart, blockLength);
  }

  List<_StyleRange> _extractInlineStyles(int blockStart, int blockLength) {
    final styles = <_StyleRange>[];
    final deltaOps = _controller.document.toDelta().toList();
    var currentOffset = 0;
    final blockEnd = blockStart + blockLength;

    for (final op in deltaOps) {
      final opLength = op.data is String ? (op.data! as String).length : 1;
      final opStart = currentOffset;
      final opEnd = currentOffset + opLength;

      if (opStart < blockEnd && opEnd > blockStart) {
        final rangeStart = opStart > blockStart ? opStart : blockStart;
        final rangeEnd = opEnd < blockEnd ? opEnd : blockEnd;
        final rangeLength = rangeEnd - rangeStart;

        if (rangeLength > 0 && op.attributes != null) {
          final attrs = op.attributes!;
          final relativeStart = rangeStart - blockStart;

          if (attrs.containsKey(Attribute.bold.key)) {
            styles.add((start: relativeStart, length: rangeLength, attribute: Attribute.bold));
          }
          if (attrs.containsKey(Attribute.italic.key)) {
            styles.add((start: relativeStart, length: rangeLength, attribute: Attribute.italic));
          }
          if (attrs.containsKey(Attribute.underline.key)) {
            styles.add((start: relativeStart, length: rangeLength, attribute: Attribute.underline));
          }
        }
      }

      currentOffset = opEnd;
      if (currentOffset >= blockEnd) break;
    }

    return styles;
  }

  void _storePreservedStyles(int blockStart, List<_StyleRange> styles) {
    _preservedStylesByBlock ??= <int, List<_StyleRange>>{};
    _preservedStylesByBlock![blockStart] = List.from(styles);
  }

  List<_StyleRange> _getPreservedStyles(int blockStart) {
    final styles = _preservedStylesByBlock?[blockStart] ?? [];
    return List.from(styles);
  }

  void _clearPreservedStyles(int blockStart) {
    _preservedStylesByBlock?.remove(blockStart);
  }

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
    final (blockStart, blockLength) = _getBlockRange();
    final cursorPos = _controller.selection.baseOffset;
    final selectionLength =
        (_controller.selection.extentOffset - _controller.selection.baseOffset).abs();
    final selectionStart = cursorPos - blockStart;
    final selectionEnd = selectionStart + selectionLength;

    final hasHeaderOrLink = currentStyle.attributes.keys
        .any((key) => [Attribute.header.key, Attribute.link.key].contains(key));

    if (hasHeaderOrLink) {
      wipeAllStyles(retainStyles: {Attribute.underline.key});
      _controller.formatSelection(textAttribute);

      if (blockLength > 0) {
        final extractedStyles = _extractInlineStyles(blockStart, blockLength);
        final preservedStyles = _getPreservedStyles(blockStart);
        final mergedStyles = <_StyleRange>[...extractedStyles];

        for (final preserved in preservedStyles) {
          final preservedEnd = preserved.start + preserved.length;
          if ((preservedEnd <= selectionStart || preserved.start >= selectionEnd) &&
              !mergedStyles.any(
                (existing) =>
                    existing.attribute.key == preserved.attribute.key &&
                    existing.start == preserved.start &&
                    existing.length == preserved.length,
              )) {
            mergedStyles.add(preserved);
          }
        }

        if (mergedStyles.isNotEmpty) {
          _storePreservedStyles(blockStart, mergedStyles);
          _restoreInlineStyles(mergedStyles, blockStart);
        } else {
          _clearPreservedStyles(blockStart);
        }
      }
      return;
    }

    final mutuallyExclusiveStyles = [Attribute.bold.key, Attribute.italic.key];
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

typedef _StyleRange = ({
  int start,
  int length,
  Attribute<dynamic> attribute,
});
