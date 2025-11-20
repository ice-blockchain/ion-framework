// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/foundation.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:ion/app/services/markdown/quill.dart';

/// Represents a PMO (Positional Markdown Override) tag.
class PmoTag {
  const PmoTag(this.start, this.end, this.replacement);

  final int start;
  final int end;
  final String replacement;

  List<String> toTag() => ['pmo', '$start:$end', replacement];

  @override
  String toString() => 'PmoTag($start, $end, $replacement)';
}

/// Result of the conversion containing plain text and PMO tags.
typedef PmoConversionResult = ({String text, List<PmoTag> tags});

typedef _ParsedPmoTag = ({int start, int end, String replacement});

/// Abstract converter for Delta and Markdown transformations.
abstract class DeltaMarkdownConverter {
  /// Maps a Delta JSON list to [PmoConversionResult].
  static Future<PmoConversionResult> mapDeltaToPmo(List<dynamic> deltaJson) async {
    return compute(_mapDeltaToPmo, deltaJson);
  }

  /// Internal static function for use with [compute].
  static PmoConversionResult _mapDeltaToPmo(List<dynamic> deltaJson) {
    final delta = Delta.fromJson(deltaJson);
    final buffer = StringBuffer();
    final pmoTags = <PmoTag>[];

    var currentIndex = 0;
    var lineStartIndex = 0;
    var inCodeBlock = false;

    // Quill's canonical delta format: block attributes are attached to the newline
    // character at the end of each line. Each line typically has its own insert operation
    // with attributes on the newline, though text content may contain newlines.

    for (final op in delta.operations) {
      if (op.key == 'insert') {
        final data = op.data;
        final attributes = op.attributes;

        if (data is String) {
          final result = _processStringContent(
            content: data,
            attributes: attributes,
            currentIndex: currentIndex,
            lineStartIndex: lineStartIndex,
            inCodeBlock: inCodeBlock,
            pmoTags: pmoTags,
          );

          buffer.write(data);
          currentIndex += data.length;
          lineStartIndex = result.lineStartIndex;
          inCodeBlock = result.inCodeBlock;
        } else if (data is Map) {
          final placeholder = _processEmbed(
            data: data,
            currentIndex: currentIndex,
            pmoTags: pmoTags,
          );

          buffer.write(placeholder);
          currentIndex += placeholder.length;
          lineStartIndex = currentIndex;
        }
      }
    }

    // Close any open code block at the end of the document
    if (inCodeBlock) {
      pmoTags.add(PmoTag(currentIndex, currentIndex, '\n```'));
    }

    return (text: buffer.toString(), tags: pmoTags);
  }

  /// Processes string content, handling newlines, block attributes, and inline attributes.
  static ({
    int lineStartIndex,
    bool inCodeBlock,
  }) _processStringContent({
    required String content,
    required Map<String, dynamic>? attributes,
    required int currentIndex,
    required int lineStartIndex,
    required bool inCodeBlock,
    required List<PmoTag> pmoTags,
  }) {
    var updatedLineStartIndex = lineStartIndex;
    var updatedInCodeBlock = inCodeBlock;

    // Process content character by character to detect newlines.
    // When a newline is found, check if this operation has block attributes
    // (Quill attaches block attributes to the newline character).
    for (var i = 0; i < content.length; i++) {
      if (content[i] == '\n') {
        final result = _processBlockAttributes(
          attributes: attributes,
          lineStartIndex: updatedLineStartIndex,
          currentIndex: currentIndex,
          charIndex: i,
          inCodeBlock: updatedInCodeBlock,
          pmoTags: pmoTags,
        );

        updatedInCodeBlock = result.inCodeBlock;
        updatedLineStartIndex = currentIndex + i + 1;
      }
    }

    // Process inline attributes (only for content without newlines)
    if (attributes != null && attributes.isNotEmpty && !content.contains('\n')) {
      _processInlineAttributes(
        content: content,
        attributes: attributes,
        currentIndex: currentIndex,
        pmoTags: pmoTags,
      );
    }

    return (
      lineStartIndex: updatedLineStartIndex,
      inCodeBlock: updatedInCodeBlock,
    );
  }

  /// Processes block-level attributes (headers, lists, blockquotes, code blocks).
  static ({bool inCodeBlock}) _processBlockAttributes({
    required Map<String, dynamic>? attributes,
    required int lineStartIndex,
    required int currentIndex,
    required int charIndex,
    required bool inCodeBlock,
    required List<PmoTag> pmoTags,
  }) {
    var updatedInCodeBlock = inCodeBlock;

    // Check for code block transitions (must check even when attributes is null)
    final isCodeBlockLine = attributes?.containsKey('code-block') ?? false;

    // Enter code block: transition from non-code-block to code-block
    if (isCodeBlockLine && !updatedInCodeBlock) {
      // Add opening fence before the line content
      pmoTags.add(PmoTag(lineStartIndex, lineStartIndex, '```\n'));
      updatedInCodeBlock = true;
    }

    // Exit code block: transition from code-block to non-code-block
    if (!isCodeBlockLine && updatedInCodeBlock) {
      // Add closing fence right after the newline of the previous (last code block) line
      final newlinePosition = currentIndex + charIndex;
      pmoTags.add(PmoTag(newlinePosition + 1, newlinePosition + 1, '\n```'));
      updatedInCodeBlock = false;
    }

    // Process other block attributes
    if (attributes != null) {
      if (attributes.containsKey('header')) {
        final level = attributes['header'] as int;
        final hashes = '#' * level;
        // Insert hashes at the start of the line
        pmoTags.add(PmoTag(lineStartIndex, lineStartIndex, '$hashes '));
      }
      if (attributes.containsKey('list')) {
        final listType = attributes['list'] as String;
        final marker = listType == 'ordered' ? '1. ' : '- ';
        pmoTags.add(PmoTag(lineStartIndex, lineStartIndex, marker));
      }
      if (attributes.containsKey('blockquote')) {
        pmoTags.add(PmoTag(lineStartIndex, lineStartIndex, '> '));
      }
    }

    return (inCodeBlock: updatedInCodeBlock);
  }

  /// Processes inline attributes (bold, italic, strike, underline, code, link).
  static void _processInlineAttributes({
    required String content,
    required Map<String, dynamic> attributes,
    required int currentIndex,
    required List<PmoTag> pmoTags,
  }) {
    var replacement = content;
    var hasReplacement = false;

    if (attributes.containsKey('bold')) {
      replacement = '**$replacement**';
      hasReplacement = true;
    }
    if (attributes.containsKey('italic')) {
      replacement = '*$replacement*';
      hasReplacement = true;
    }
    if (attributes.containsKey('strike')) {
      replacement = '~~$replacement~~';
      hasReplacement = true;
    }
    if (attributes.containsKey('underline')) {
      replacement = '<u>$replacement</u>';
      hasReplacement = true;
    }
    if (attributes.containsKey('code')) {
      replacement = '`$replacement`';
      hasReplacement = true;
    }
    if (attributes.containsKey('link')) {
      final link = attributes['link'];
      replacement = '[$content]($link)';
      hasReplacement = true;
    }

    if (hasReplacement && content.trim().isNotEmpty) {
      pmoTags.add(PmoTag(currentIndex, currentIndex + content.length, replacement));
    }
  }

  /// Processes embed data (images, separators, code blocks).
  static String _processEmbed({
    required Map<dynamic, dynamic> data,
    required int currentIndex,
    required List<PmoTag> pmoTags,
  }) {
    if (data.containsKey('text-editor-single-image')) {
      final imageUrl = data['text-editor-single-image'];
      const placeholder = ' ';
      final start = currentIndex;
      final end = currentIndex + placeholder.length;
      final replacement = '![]($imageUrl)';

      pmoTags.add(PmoTag(start, end, replacement));
      return placeholder;
    } else if (data.containsKey('text-editor-separator')) {
      const placeholder = '\n';
      final start = currentIndex;
      final end = currentIndex + placeholder.length;
      const replacement = '\n---\n';

      pmoTags.add(PmoTag(start, end, replacement));
      return placeholder;
    } else if (data.containsKey('text-editor-code')) {
      final code = data['text-editor-code'];
      const placeholder = '\n';
      final start = currentIndex;
      final end = currentIndex + placeholder.length;
      final replacement = '\n```\n$code\n```\n';

      pmoTags.add(PmoTag(start, end, replacement));
      return placeholder;
    }

    // Fallback: empty placeholder if embed type is unknown
    return '';
  }

  /// Maps markdown (via PMO tags) to Delta.
  ///
  /// This is used for backward compatibility when reading posts/articles
  /// that have PMO tags but no richText Delta.
  ///
  /// Parameters:
  /// - [plainText]: The plain text content from the event
  /// - [pmoTags]: List of PMO tags in format ['pmo', 'start:end', 'markdown replacement']
  ///
  /// Returns: Delta mapped from the markdown created by applying PMO tags
  static Delta mapMarkdownToDelta(String plainText, List<List<String>> pmoTags) {
    if (pmoTags.isEmpty) {
      // No PMO tags, return plain text as Delta
      return Delta()..insert('$plainText\n');
    }

    // Parse PMO tags
    final parsedTags = pmoTags
        .where((tag) => tag.length >= 3 && tag[0] == 'pmo')
        .map((tag) {
          final indices = tag[1].split(':');
          if (indices.length != 2) return null;
          final start = int.tryParse(indices[0]);
          final end = int.tryParse(indices[1]);
          if (start == null || end == null) return null;
          return (start: start, end: end, replacement: tag[2]);
        })
        .whereType<_ParsedPmoTag>()
        .toList()

      // Sort by start position ascending to process from start to end
      ..sort((a, b) => a.start.compareTo(b.start));

    // Build markdown by applying replacements in order
    final buffer = StringBuffer();
    var currentPos = 0;

    for (final tag in parsedTags) {
      // Validate indices against original plain text
      if (tag.start < currentPos ||
          tag.start > plainText.length ||
          tag.end > plainText.length ||
          tag.start > tag.end) {
        continue; // Skip invalid or overlapping tags
      }

      // Add text before this tag
      if (tag.start > currentPos) {
        buffer.write(plainText.substring(currentPos, tag.start));
      }

      // Add the markdown replacement
      buffer.write(tag.replacement);

      currentPos = tag.end;
    }

    // Add remaining text after last tag
    if (currentPos < plainText.length) {
      buffer.write(plainText.substring(currentPos));
    }

    final markdown = buffer.toString();

    // Convert markdown to Delta
    return markdownToDelta(markdown);
  }
}
