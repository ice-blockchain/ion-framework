// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_quill/quill_delta.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/ion_connect/model/pmo_tag.f.dart';
import 'package:ion/app/services/markdown/delta_markdown_converter.dart';
import 'package:ion/app/services/markdown/quill.dart';

/// Trims leading and trailing whitespace on each line in Delta operations.
/// This modifies the Delta by trimming whitespace at line boundaries (`\n`)
/// across the whole Delta (not per insert op).
///
/// Note: Quill attaches block-level attributes (e.g. `code-block`) to the newline.
/// We therefore avoid trimming code-block lines, and we keep block attributes only
/// on the newline when splitting string ops containing newlines.
Delta trimLineWhitespaceInDelta(Delta delta) {
  final trimmedDelta = Delta();

  final lineBuffer = <({dynamic data, Map<String, dynamic>? attributes})>[];

  const blockAttributeKeys = <String>{
    'header',
    'list',
    'blockquote',
    'code-block',
  };

  Map<String, dynamic>? withoutBlockAttributes(Map<String, dynamic>? attrs) {
    if (attrs == null || attrs.isEmpty) return attrs;
    if (!attrs.keys.any(blockAttributeKeys.contains)) return attrs;
    final copy = Map<String, dynamic>.from(attrs)
      ..removeWhere((k, _) => blockAttributeKeys.contains(k));
    return copy.isEmpty ? null : copy;
  }

  void trimLineBuffer() {
    void trimEdge({required bool leading}) {
      while (lineBuffer.isNotEmpty) {
        final index = leading ? 0 : (lineBuffer.length - 1);
        final seg = lineBuffer[index];
        if (seg.data is! String) {
          return; // embed counts as content
        }

        final text = seg.data! as String;
        final trimmed = leading ? text.trimLeft() : text.trimRight();

        if (trimmed.isEmpty) {
          lineBuffer.removeAt(index);
          continue;
        }

        if (trimmed != text) {
          lineBuffer[index] = (data: trimmed, attributes: seg.attributes);
        }
        return;
      }
    }

    trimEdge(leading: true);
    trimEdge(leading: false);
  }

  void flushLineBuffer() {
    for (final seg in lineBuffer) {
      if (seg.data is String) {
        final s = seg.data! as String;
        if (s.isEmpty) continue;
        trimmedDelta.insert(s, seg.attributes);
      } else {
        trimmedDelta.insert(seg.data, seg.attributes);
      }
    }
    lineBuffer.clear();
  }

  void emitLineWithNewline({required Map<String, dynamic>? newlineAttributes}) {
    final isCodeBlockLine = newlineAttributes?.containsKey('code-block') ?? false;
    if (!isCodeBlockLine) {
      trimLineBuffer();
    }
    flushLineBuffer();
    trimmedDelta.insert('\n', newlineAttributes);
  }

  void appendStringInsert(String text, Map<String, dynamic>? attributes) {
    final inlineAttrs = withoutBlockAttributes(attributes);
    var start = 0;
    while (start <= text.length) {
      final newlineIndex = text.indexOf('\n', start);
      if (newlineIndex == -1) {
        final part = text.substring(start);
        if (part.isNotEmpty) {
          lineBuffer.add((data: part, attributes: inlineAttrs));
        }
        break;
      }

      final before = text.substring(start, newlineIndex);
      if (before.isNotEmpty) {
        lineBuffer.add((data: before, attributes: inlineAttrs));
      }

      emitLineWithNewline(newlineAttributes: attributes);
      start = newlineIndex + 1;
    }
  }

  for (final op in delta.operations) {
    if (op.key != 'insert') {
      flushLineBuffer();
      trimmedDelta.push(op);
      continue;
    }

    final data = op.data;
    if (data is String) {
      appendStringInsert(data, op.attributes);
    } else {
      lineBuffer.add((data: data, attributes: op.attributes));
    }
  }

  if (lineBuffer.isNotEmpty) {
    trimLineBuffer();
    flushLineBuffer();
  }

  return trimmedDelta;
}

/// Trims extra empty lines from text according to the rules:
/// - Removes empty lines at the start
/// - Removes empty lines at the end
/// - If [allowExtraLineBreak] is true: allows up to 2 consecutive newlines between paragraphs
/// - If [allowExtraLineBreak] is false: collapses 2+ consecutive newlines to a single newline
///
/// Returns the trimmed text and a function to adjust character positions.
({String trimmedText, int Function(int) adjustPosition}) trimEmptyLines(
  String text, {
  bool allowExtraLineBreak = true,
}) {
  if (text.isEmpty) {
    return (trimmedText: text, adjustPosition: (pos) => pos);
  }

  var startIndex = 0;
  while (startIndex < text.length && text[startIndex] == '\n') {
    startIndex++;
  }

  var endIndex = text.length;
  while (endIndex > startIndex && text[endIndex - 1] == '\n') {
    endIndex--;
  }

  if (startIndex >= endIndex) {
    return (trimmedText: '', adjustPosition: (pos) => 0);
  }

  final buffer = StringBuffer();
  final positionMap = List<int?>.filled(text.length, null);
  var newPos = 0;
  var newlineCount = 0;

  for (var i = startIndex; i < endIndex; i++) {
    if (text[i] == '\n') {
      newlineCount++;
      final maxNewlines = allowExtraLineBreak ? 2 : 1;
      if (newlineCount <= maxNewlines) {
        buffer.write('\n');
        positionMap[i] = newPos;
        newPos++;
      } else {
        positionMap[i] = newPos - 1;
      }
    } else {
      buffer.write(text[i]);
      positionMap[i] = newPos;
      newPos++;
      newlineCount = 0;
    }
  }

  final trimmedText = buffer.toString();

  int adjustPosition(int pos) {
    if (pos < startIndex) return 0;
    if (pos >= endIndex) return trimmedText.length;

    var searchPos = pos;
    while (searchPos >= startIndex && positionMap[searchPos] == null) {
      searchPos--;
    }

    return searchPos < startIndex ? 0 : positionMap[searchPos]!;
  }

  return (trimmedText: trimmedText, adjustPosition: adjustPosition);
}

List<PmoTag> adjustPmoTagPositions(
  List<PmoTag> tags,
  int Function(int) adjustPosition,
) {
  return tags
      .map((tag) {
        final adjustedStart = adjustPosition(tag.start);
        final adjustedEnd = adjustPosition(tag.end);

        if (adjustedStart < 0 || adjustedEnd < adjustedStart) {
          return null;
        }

        return PmoTag(
          start: adjustedStart,
          end: adjustedEnd,
          replacement: tag.replacement,
        );
      })
      .whereType<PmoTag>()
      .toList();
}

/// Converts Delta JSON to plain text and PMO tags.
///
/// Returns a record containing the content to sign and the PMO tags.
/// Throws [ContentConversionException] if conversion fails.
Future<({String contentToSign, List<List<String>> pmoTags})> convertDeltaToPmoTags(
  List<dynamic> deltaJson,
) async {
  try {
    final delta = Delta.fromJson(deltaJson);
    final trimmedDelta = trimLineWhitespaceInDelta(delta);

    final result = await DeltaMarkdownConverter.mapDeltaToPmo(trimmedDelta.toJson());

    final trimResult = trimEmptyLines(result.text);
    final adjustedTags = adjustPmoTagPositions(result.tags, trimResult.adjustPosition);
    final pmoTags = adjustedTags.map((t) => t.toTag()).toList();
    return (contentToSign: trimResult.trimmedText, pmoTags: pmoTags);
  } catch (e) {
    throw ContentConversionException(e, conversionType: 'Delta to PMO tags');
  }
}

/// Converts Delta to plain text and PMO tags.
///
/// Returns a record containing the content to sign and the PMO tags.
/// Throws [ContentConversionException] if conversion fails.
Future<({String contentToSign, List<List<String>> pmoTags})> convertDeltaToPmoTagsFromDelta(
  Delta delta,
) async {
  return convertDeltaToPmoTags(delta.toJson());
}

/// Converts Delta to markdown content.
///
/// Applies trimming to remove extra empty lines and trim whitespace on individual lines.
/// Throws [ContentConversionException] if conversion fails.
String convertDeltaToMarkdown(Delta delta) {
  try {
    final trimmedDelta = trimLineWhitespaceInDelta(delta);
    final markdown = deltaToMarkdown(trimmedDelta);
    final trimResult = trimEmptyLines(markdown);
    return trimResult.trimmedText;
  } catch (e) {
    throw ContentConversionException(e, conversionType: 'Delta to markdown');
  }
}

/// Converts markdown content to Delta and then to plain text and PMO tags.
///
/// This is for backward compatibility when content is markdown instead of Delta.
/// Returns a record containing the content to sign and the PMO tags.
/// Throws [ContentConversionException] if conversion fails.
Future<({String contentToSign, List<List<String>> pmoTags})> convertMarkdownToPmoTags(
  String markdownContent,
) async {
  try {
    // Convert markdown → Delta → plain text + PMO tags
    // The converter automatically trims the trailing newline that markdownToDelta adds
    final result = await DeltaMarkdownConverter.mapMarkdownToPmo(markdownContent);
    final pmoTags = result.tags.map((t) => t.toTag()).toList();
    return (contentToSign: result.text, pmoTags: pmoTags);
  } catch (e) {
    throw ContentConversionException(e, conversionType: 'markdown to PMO tags');
  }
}
