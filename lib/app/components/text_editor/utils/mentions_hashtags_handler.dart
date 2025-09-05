// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:ion/app/components/text_editor/attributes.dart';
import 'package:ion/app/components/text_editor/utils/text_editor_typing_listener.dart';
import 'package:ion/app/features/feed/providers/suggestions/suggestions_notifier_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
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

  void onMentionSuggestionSelected(({String pubkey, String username}) pubkeyUsernamePair) {
    final userMetadata = ref.read(userMetadataSyncProvider(pubkeyUsernamePair.pubkey));
    if (userMetadata == null) return;
    final userMetadataEncoded = userMetadata.toEventReference().encode();

    final fullText = controller.document.toPlainText();
    final cursorIndex = controller.selection.baseOffset;
    final tags = _extractTags(fullText);
    final tag = tags.lastWhere(
      (t) => t.start < cursorIndex && t.start + t.length >= cursorIndex - 1,
      orElse: () => _TagInfo(start: -1, length: 0, text: '', tagChar: ''),
    );
    if (tag.start == -1) return;

    final suggestionWithTagChar = pubkeyUsernamePair.username.startsWith(tag.tagChar)
        ? pubkeyUsernamePair.username
        : '${tag.tagChar}${pubkeyUsernamePair.username}';

    controller
      ..removeListener(editorListener)
      // remove the current '@...' placeholder
      ..replaceText(tag.start, tag.length, suggestionWithTagChar, null)
      // apply MentionAttribute using the encoded reference as its value
      ..formatText(
        tag.start,
        suggestionWithTagChar.length,
        MentionAttribute.withValue(userMetadataEncoded),
      )
      // add a trailing space and move cursor after it
      ..replaceText(tag.start + suggestionWithTagChar.length, 0, ' ', null)
      ..updateSelection(
        TextSelection.collapsed(offset: tag.start + suggestionWithTagChar.length + 1),
        ChangeSource.local,
      )
      ..addListener(editorListener);

    // reapply attributes for other tags and reset suggestions
    _reapplyAllTags(controller.document.toPlainText());
    ref.invalidate(suggestionsNotifierProvider);
  }

  void onSuggestionSelected(String suggestion) {
    final fullText = controller.document.toPlainText();
    final cursorIndex = controller.selection.baseOffset;

    final tags = _extractTags(fullText);
    final tag = tags.lastWhere(
      (t) => t.start < cursorIndex && t.start + t.length >= cursorIndex - 1,
      orElse: () => _TagInfo(start: -1, length: 0, text: '', tagChar: ''),
    );

    if (tag.start == -1) return;

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

    for (final tag in tags) {
      final attribute = _getAttribute(tag.tagChar);
      if (attribute != null) {
        controller.formatText(tag.start, tag.length, attribute);
      }
    }
  }

  _TagInfo? _findActiveTagNearCursor(String text, int cursorIndex) {
    //if there is only @ in text return it as a Tag
    if (text == '@\n') {
      return _TagInfo(start: 1, length: 1, text: '', tagChar: '@');
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
