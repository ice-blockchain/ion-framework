// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:ion/app/components/text_editor/attributes.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/models/mention_embed_data.f.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/services/mention_insertion_service.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/text_editor_mention_embed_builder.dart';
import 'package:ion/app/components/text_editor/utils/quill_text_utils.dart';
import 'package:ion/app/components/text_editor/utils/text_editor_typing_listener.dart';
import 'package:ion/app/features/feed/providers/suggestions/suggestions_notifier_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/user_token_market_cap_provider.r.dart';
import 'package:ion/app/services/text_parser/model/text_matcher.dart';

class MentionsHashtagsHandler extends TextEditorTypingListener {
  MentionsHashtagsHandler({
    required super.controller,
    required super.focusNode,
    required super.context,
    required super.ref,
  });

  // Track last processed text to avoid heavy reformat on selection-only changes
  String? _lastProcessedText;

  static const int _invalidTagStart = -1;

  @override
  void onTextChanged(
    String text,
    int cursorIndex, {
    required bool isBackspace,
    required bool cursorMoved,
  }) {
    final didTextChange = _lastProcessedText != text;
    _lastProcessedText = text;

    // Only reapply attributes if text changed
    if (didTextChange) {
      _reapplyAllTags(text);
    }

    final activeTag = _findActiveTagNearCursor(text, cursorIndex);
    if (activeTag == null) {
      ref.invalidate(suggestionsNotifierProvider);
    } else {
      ref
          .read(suggestionsNotifierProvider.notifier)
          .updateSuggestions(activeTag.text, activeTag.tagChar);
    }
  }

  @override
  void onFocusLost() {
    ref.invalidate(suggestionsNotifierProvider);
  }

  Future<void> onMentionSuggestionSelected(
    ({String pubkey, String username}) pubkeyUsernamePair,
  ) async {
    final fullText = controller.document.toPlainText();
    final cursorIndex = controller.selection.baseOffset;
    final tag = _findTagAtCursor(fullText, cursorIndex);
    if (tag.start == _invalidTagStart) return;

    final mentionData = MentionEmbedData(
      pubkey: pubkeyUsernamePair.pubkey,
      username: pubkeyUsernamePair.username,
    );

    // Check cache first (non-blocking) - if available, insert as embed immediately
    final cachedMarketCap = _getCachedMarketCap(pubkeyUsernamePair.pubkey);

    controller.removeListener(editorListener);
    try {
      if (cachedMarketCap != null) {
        // Insert as embed (widget) immediately - even if marketCap is 0
        MentionInsertionService.insertMention(
          controller,
          tag.start,
          tag.length,
          mentionData,
        );
      } else {
        // Insert as text + mention attribute (colored text) immediately
        // Don't set showMarketCapKey since market cap doesn't exist at insertion time
        // This means it won't upgrade later.
        MentionInsertionService.insertMentionAsText(
          controller,
          tag.start,
          tag.length,
          pubkeyUsernamePair.pubkey,
          pubkeyUsernamePair.username,
        );
      }
    } finally {
      controller.addListener(editorListener);
    }

    // reapply attributes for other tags and reset suggestions
    _reapplyAllTags(controller.document.toPlainText());
    ref.invalidate(suggestionsNotifierProvider);
  }

  // Gets cached market cap value (non-blocking for optimistic behavior, returns null if not cached).
  double? _getCachedMarketCap(String pubkey) {
    return ref.read(userTokenMarketCapProvider(pubkey));
  }

  void onSuggestionSelected(String suggestion) {
    final fullText = controller.document.toPlainText();
    final cursorIndex = controller.selection.baseOffset;
    final tag = _findTagAtCursor(fullText, cursorIndex);
    if (tag.start == _invalidTagStart) return;

    final attribute = _getAttribute(tag.tagChar);

    if (attribute != null) {
      controller.removeListener(editorListener);
      try {
        final suggestionWithTagChar =
            suggestion.startsWith(tag.tagChar) ? suggestion : '${tag.tagChar}$suggestion';
        controller
          ..replaceText(tag.start, tag.length, suggestionWithTagChar, null)
          ..formatText(tag.start, suggestionWithTagChar.length, attribute)
          ..replaceText(tag.start + suggestionWithTagChar.length, 0, ' ', null)
          ..updateSelection(
            TextSelection.collapsed(offset: tag.start + suggestionWithTagChar.length + 1),
            ChangeSource.local,
          );
      } finally {
        controller.addListener(editorListener);
      }

      _reapplyAllTags(controller.document.toPlainText());
      ref.invalidate(suggestionsNotifierProvider);
    }
  }

  void _reapplyAllTags(String fullText) {
    controller.removeListener(editorListener);
    try {
      final tags = _extractTags(fullText);
      _applyTagAttributes(tags);
    } finally {
      controller.addListener(editorListener);
    }
  }

  List<_TagInfo> _extractTags(String text) {
    final regex = RegExp(
      '${const CashtagMatcher().pattern}|${const HashtagMatcher().pattern}|${const MentionMatcher().pattern}',
    );
    final matches = regex.allMatches(text);

    return matches.map((match) {
      final tagText = match.group(0)!;
      final tagChar = tagText[0];
      return _TagInfo(
        start: match.start,
        length: tagText.length,
        text: tagText,
        tagChar: tagChar,
      );
    }).toList();
  }

  void _applyTagAttributes(List<_TagInfo> tags) {
    final docLength = controller.document.length;

    controller
      ..formatText(0, docLength, const HashtagAttribute.unset())
      ..formatText(0, docLength, const CashtagAttribute.unset());

    final deltaOps = controller.document.toDelta().toList();

    for (final tag in tags) {
      final attribute = _getAttribute(tag.tagChar);
      if (attribute != null) {
        final overlaps = QuillTextUtils.rangeOverlapsOpsWithAttributes(
          deltaOps,
          tag.start,
          tag.length,
        );
        if (overlaps) {
          continue;
        }
        // remove any link within the tag range to avoid overlapping attributes
        controller
          ..formatText(tag.start, tag.length, Attribute.clone(Attribute.link, null))
          ..formatText(tag.start, tag.length, attribute);
      }
    }
  }

  _TagInfo _findTagAtCursor(String fullText, int cursorIndex) {
    final tags = _extractTags(fullText);
    return tags.lastWhere(
      (t) => t.start < cursorIndex && t.start + t.length >= cursorIndex - 1,
      orElse: () => _TagInfo(start: _invalidTagStart, length: 0, text: '', tagChar: ''),
    );
  }

  _TagInfo? _findActiveTagNearCursor(String text, int cursorIndex) {
    //if there is only @ in text return it as a Tag
    if (text == '$mentionPrefix\n') {
      return _TagInfo(start: 1, length: 1, text: '', tagChar: mentionPrefix);
    }
    final tags = _extractTags(text);
    for (final tag in tags) {
      if (cursorIndex > tag.start && cursorIndex <= tag.start + tag.length) {
        return tag;
      }
    }
    return null;
  }

  Attribute<String?>? _getAttribute(String tagChar) {
    return switch (tagChar) {
      '#' => HashtagAttribute.withValue(tagChar),
      r'$' => CashtagAttribute.withValue(tagChar),
      _ => null,
    };
  }
}

class _TagInfo {
  _TagInfo({
    required this.start,
    required this.length,
    required this.text,
    required this.tagChar,
  });

  final int start;
  final int length;
  final String text;
  final String tagChar;
}
