// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:ion/app/components/text_editor/utils/quill_text_utils.dart';
import 'package:ion/app/components/text_editor/utils/text_editor_typing_listener.dart';
import 'package:ion/app/services/text_parser/model/text_matcher.dart';
import 'package:ion/app/services/text_parser/text_parser.dart';

/// Handles automatic link detection and formatting in the text editor.
///
/// This handler:
/// - Detects URLs in plain text and applies link formatting
/// - Preserves manually assigned links (via add link flow)
/// - Respects other inline attributes (mentions, hashtags, cashtags)
/// - Allows URLs to be extended character-by-character (e.g., "x.co" -> "x.com")
/// - Prevents link attributes from bleeding into surrounding text
class LinksHandler extends TextEditorTypingListener {
  LinksHandler({
    required super.controller,
    required super.focusNode,
    required super.context,
    required super.ref,
  });

  final _urlParser = TextParser(matchers: {const UrlMatcher()});

  /// Prevents re-entrant formatting during formatting operations
  bool _isFormatting = false;

  /// Debounce timer to avoid excessive formatting on rapid typing
  Timer? _debounceTimer;

  /// Tracks the last processed text to skip formatting on selection-only changes
  String? _lastProcessedText;

  /// Marker attribute to distinguish auto-detected links from manual links
  static const _autoLinkMarker = Attribute('autoLink', AttributeScope.inline, true);
  static const _clearAutoLinkMarker = Attribute('autoLink', AttributeScope.inline, null);

  /// Debounce duration for link formatting
  static const _formatDebounce = Duration(milliseconds: 150);

  @override
  void onTextChanged(
    String text,
    int cursorIndex, {
    required bool isBackspace,
    required bool cursorMoved,
  }) {
    // Don't format while formatting is in progress
    if (_isFormatting) return;

    // Skip formatting if only the selection changed, not the text
    if (_lastProcessedText == text) return;
    _lastProcessedText = text;

    // Debounce formatting to avoid excessive processing during rapid typing
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_formatDebounce, () => _formatLinks(text));
  }

  @override
  void onFocusLost() {
    // No action needed on focus lost
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Formats links in the document by detecting URLs and applying/removing link attributes.
  void _formatLinks(String text) {
    _isFormatting = true;

    try {
      // Parse text to find all valid URLs
      final detectedUrls = _parseUrls(text);

      // Get current document state
      final documentOps = controller.document.toDelta().toList();

      // Remove auto-link attributes from text that's no longer part of a valid URL
      _removeInvalidAutoLinks(documentOps, detectedUrls);

      // Apply link attributes to newly detected URLs
      _applyAutoLinks(documentOps, detectedUrls);

      // Clear link formatting at cursor if needed to prevent attribute bleeding
      _preventLinkAttributeBleeding(text, detectedUrls);
    } finally {
      _isFormatting = false;
    }
  }

  /// Parses text and returns a list of detected URL ranges.
  List<_UrlRange> _parseUrls(String text) {
    final matches = _urlParser.parse(text, onlyMatches: true);
    return matches
        .where((match) => match.text.isNotEmpty)
        .map(
          (match) => _UrlRange(
            start: match.offset,
            end: match.offset + match.text.length,
            url: match.text,
          ),
        )
        .toList();
  }

  /// Removes auto-link attributes from text that's no longer part of a valid URL.
  void _removeInvalidAutoLinks(List<Operation> ops, List<_UrlRange> validUrls) {
    var offset = 0;

    for (final op in ops) {
      final attrs = op.attributes;
      final len = _getOperationLength(op);

      // Only process operations that have auto-link attributes
      if (_hasAutoLinkAttributes(attrs)) {
        // Check if this operation is still covered by a valid URL
        if (!_isWithinValidUrl(offset, len, validUrls)) {
          _clearLinkAttributes(offset, len);
        }
      }

      offset += len;
    }
  }

  /// Applies link attributes to newly detected URLs.
  void _applyAutoLinks(List<Operation> ops, List<_UrlRange> detectedUrls) {
    for (final urlRange in detectedUrls) {
      // Skip if this URL range overlaps with protected attributes
      // (mentions, hashtags, manual links, etc.)
      if (_hasProtectedAttributes(ops, urlRange)) {
        continue;
      }

      // Apply link and auto-link marker attributes
      controller
        ..formatText(urlRange.start, urlRange.length, LinkAttribute(urlRange.url))
        ..formatText(urlRange.start, urlRange.length, _autoLinkMarker);
    }
  }

  /// Prevents link attributes from bleeding into text typed after a URL.
  ///
  /// When typing after a URL followed by whitespace, we clear the link
  /// formatting at the cursor to prevent new text from inheriting it.
  void _preventLinkAttributeBleeding(String text, List<_UrlRange> validUrls) {
    final cursorPos = controller.selection.baseOffset;

    // Only process if cursor is in a valid position
    if (cursorPos <= 0 || cursorPos >= controller.document.length) {
      return;
    }

    final style = controller.getSelectionStyle();

    // Only process if cursor has auto-link attributes
    if (!_hasAutoLinkAttributes(style.attributes)) {
      return;
    }

    // Check if cursor is right after a URL followed by whitespace
    if (_isCursorAfterUrlWithWhitespace(cursorPos, text, validUrls)) {
      controller
        ..formatSelection(Attribute.clone(Attribute.link, null))
        ..formatSelection(_clearAutoLinkMarker);
    }
  }

  /// Checks if the cursor is positioned right after a URL followed by whitespace.
  bool _isCursorAfterUrlWithWhitespace(
    int cursorPos,
    String text,
    List<_UrlRange> validUrls,
  ) {
    return validUrls.any((url) {
      // Cursor must be exactly at the end of the URL
      if (cursorPos != url.end) return false;

      // Check if there's whitespace after the cursor
      if (cursorPos >= text.length) return false;

      final charAfterCursor = text[cursorPos];
      return _isWhitespace(charAfterCursor);
    });
  }

  /// Checks if the given range overlaps with protected attributes.
  ///
  /// Protected attributes include:
  /// - Mentions
  /// - Hashtags
  /// - Cashtags
  /// - Manually assigned links (without auto-link marker)
  bool _hasProtectedAttributes(List<Operation> ops, _UrlRange urlRange) {
    var offset = 0;

    for (final op in ops) {
      final len = _getOperationLength(op);
      final opRange = (start: offset, end: offset + len);

      // Check if this operation overlaps with the URL range
      if (_rangesOverlap(opRange, (start: urlRange.start, end: urlRange.end))) {
        final attrs = op.attributes;
        if (attrs != null && _hasNonAutoLinkProtectedAttributes(attrs)) {
          return true;
        }
      }

      offset += len;
    }

    return false;
  }

  /// Checks if attributes contain protected inline attributes (excluding auto-links).
  bool _hasNonAutoLinkProtectedAttributes(Map<String, dynamic> attrs) {
    return attrs.keys.any((String key) {
      // Skip if not a blocked attribute
      if (!QuillTextUtils.blockedInlineAttributeKeys.contains(key)) {
        return false;
      }

      // For link attributes, only block if it's a manual link (no auto-link marker)
      if (key == Attribute.link.key) {
        return !attrs.containsKey('autoLink');
      }

      // Block mentions, hashtags, cashtags
      return true;
    });
  }

  /// Checks if the given position range is within any valid URL range.
  bool _isWithinValidUrl(int offset, int len, List<_UrlRange> validUrls) {
    final opEnd = offset + len;
    return validUrls.any((url) => offset >= url.start && opEnd <= url.end);
  }

  /// Checks if attributes contain auto-link marker.
  bool _hasAutoLinkAttributes(Map<String, dynamic>? attrs) {
    return attrs != null && attrs.containsKey(Attribute.link.key) && attrs.containsKey('autoLink');
  }

  /// Clears link and auto-link attributes from the specified range.
  void _clearLinkAttributes(int offset, int len) {
    controller
      ..formatText(offset, len, Attribute.clone(Attribute.link, null))
      ..formatText(offset, len, _clearAutoLinkMarker);
  }

  /// Gets the length of an operation (text length or 1 for embeds).
  int _getOperationLength(Operation op) {
    return op.data is String ? (op.data! as String).length : 1;
  }

  /// Checks if two ranges overlap.
  bool _rangesOverlap(
    ({int start, int end}) range1,
    ({int start, int end}) range2,
  ) {
    return range1.start < range2.end && range2.start < range1.end;
  }

  /// Checks if a character is whitespace.
  bool _isWhitespace(String char) {
    return char == ' ' || char == '\n' || char == '\t';
  }
}

/// Represents a detected URL range in the text.
class _UrlRange {
  const _UrlRange({
    required this.start,
    required this.end,
    required this.url,
  });

  final int start;
  final int end;
  final String url;

  int get length => end - start;

  @override
  String toString() => '_UrlRange(start: $start, end: $end, url: "$url")';
}
