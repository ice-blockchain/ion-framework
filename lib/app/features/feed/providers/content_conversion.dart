// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_quill/quill_delta.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/ion_connect/model/pmo_tag.f.dart';
import 'package:ion/app/services/markdown/delta_markdown_converter.dart';
import 'package:ion/app/services/markdown/quill.dart';

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
    final result = await DeltaMarkdownConverter.mapDeltaToPmo(deltaJson);
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

/// Converts Delta JSON to plain text and PMO tags for posts.
///
/// Simplified version that only supports bold and italic formatting.
/// Skips all block-level markdown and other inline formatting.
///
/// Returns a record containing the content to sign and the PMO tags.
/// Throws [ContentConversionException] if conversion fails.
Future<({String contentToSign, List<List<String>> pmoTags})> convertDeltaToPmoTagsForPosts(
  List<dynamic> deltaJson,
) async {
  try {
    final result = await DeltaMarkdownConverter.mapDeltaToPmoForPosts(deltaJson);
    final trimResult = trimEmptyLines(result.text);
    final adjustedTags = adjustPmoTagPositions(result.tags, trimResult.adjustPosition);
    final pmoTags = adjustedTags.map((t) => t.toTag()).toList();
    return (contentToSign: trimResult.trimmedText, pmoTags: pmoTags);
  } catch (e) {
    throw ContentConversionException(e, conversionType: 'Delta to PMO tags for posts');
  }
}

/// Converts Delta to plain text and PMO tags for posts.
///
/// Simplified version that only supports bold and italic formatting.
///
/// Returns a record containing the content to sign and the PMO tags.
/// Throws [ContentConversionException] if conversion fails.
Future<({String contentToSign, List<List<String>> pmoTags})> convertDeltaToPmoTagsForPostsFromDelta(
  Delta delta,
) async {
  return convertDeltaToPmoTagsForPosts(delta.toJson());
}

/// Converts Delta to markdown content.
///
/// Throws [ContentConversionException] if conversion fails.
String convertDeltaToMarkdown(Delta delta) {
  try {
    return deltaToMarkdown(delta);
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
