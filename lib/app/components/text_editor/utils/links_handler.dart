// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:ion/app/components/text_editor/utils/quill_text_utils.dart';
import 'package:ion/app/components/text_editor/utils/text_editor_typing_listener.dart';
import 'package:ion/app/services/text_parser/model/text_matcher.dart';
import 'package:ion/app/services/text_parser/text_parser.dart';

class LinksHandler extends TextEditorTypingListener {
  LinksHandler({
    required super.controller,
    required super.focusNode,
    required super.context,
    required super.ref,
  });

  final _urlMatcher = TextParser(matchers: {const UrlMatcher()});

  bool _isFormatting = false;
  Timer? _debounceTimer;

  // Track last processed text to avoid formatting on selection-only changes
  String? _lastProcessedText;

  static const _autoLinkAttr = Attribute('autoLink', AttributeScope.inline, true);
  static const _clearAutoLinkAttr = Attribute('autoLink', AttributeScope.inline, null);

  @override
  void onTextChanged(
    String text,
    int cursorIndex, {
    required bool isBackspace,
    required bool cursorMoved,
  }) {
    if (_isFormatting) return;

    // Only (re)format when text actually changed, not on selection-only changes
    if (_lastProcessedText == text) return;
    _lastProcessedText = text;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      _formatLinks(text);
    });
  }

  @override
  void onFocusLost() {}

  void _formatLinks(String text) {
    _isFormatting = true;
    try {
      // Remove only existing link attributes
      final deltaOps = controller.document.toDelta().toList();
      var offset = 0;
      for (final op in deltaOps) {
        final attrs = op.attributes;
        final len = op.data is String ? (op.data! as String).length : 1;
        // Remove only auto-detected links (marked by autoLink) so manual links assigned with add link flow stay intact
        if (attrs != null &&
            attrs.containsKey(Attribute.link.key) &&
            attrs.containsKey('autoLink')) {
          controller
            ..formatText(
              offset,
              len,
              Attribute.clone(Attribute.link, null),
            )
            ..formatText(
              offset,
              len,
              _clearAutoLinkAttr,
            );
        }
        offset += len;
      }

      final matches = _urlMatcher.parse(text, onlyMatches: true);
      for (final match in matches) {
        final url = match.text;
        if (url.isEmpty) continue;

        final start = match.offset;
        final length = match.text.length;

        if (QuillTextUtils.rangeOverlapsOpsWithAttributes(deltaOps, start, length)) {
          continue;
        }

        controller
          ..formatText(start, length, LinkAttribute(url))
          ..formatText(start, length, _autoLinkAttr);
      }
    } finally {
      _isFormatting = false;
    }
  }
}
