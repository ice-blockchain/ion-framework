// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/foundation.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:ion/app/features/ion_connect/model/pmo_tag.f.dart';
import 'package:ion/app/services/markdown/quill.dart';

typedef _ParsedPmoTag = ({int start, int end, String replacement});

/// Result of the conversion containing plain text and PMO tags.
typedef PmoConversionResult = ({String text, List<PmoTag> tags});

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
      pmoTags.add(PmoTag(start: currentIndex, end: currentIndex, replacement: '\n```'));
    }

    return (text: buffer.toString(), tags: pmoTags);
  }

  /// Maps markdown content to plain text and PMO tags.
  ///
  /// This converts markdown → Delta → plain text + PMO tags.
  /// Automatically trims the trailing newline that markdownToDelta adds.
  ///
  /// Returns a record containing the content to sign and the PMO tags.
  static Future<PmoConversionResult> mapMarkdownToPmo(String markdownContent) async {
    final delta = markdownToDelta(markdownContent);
    final result = await mapDeltaToPmo(delta.toJson());
    // Trim trailing newline that markdownToDelta adds
    return (text: result.text.trimRight(), tags: result.tags);
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
    var lineStart = lineStartIndex;
    var inCodeBlockState = inCodeBlock;
    var segmentStart = 0;

    // Process character by character to detect newlines.
    // Block attributes are attached to the newline character in Quill's format.
    for (var i = 0; i < content.length; i++) {
      if (content[i] == '\n') {
        // Process inline attributes for the segment before this newline
        if (i > segmentStart && attributes != null && attributes.isNotEmpty) {
          final segment = content.substring(segmentStart, i);
          _processInlineAttributes(
            content: segment,
            attributes: attributes,
            currentIndex: currentIndex + segmentStart,
            pmoTags: pmoTags,
          );
        }

        inCodeBlockState = _processBlockAttributes(
          attributes: attributes,
          lineStartIndex: lineStart,
          currentIndex: currentIndex,
          charIndex: i,
          inCodeBlock: inCodeBlockState,
          pmoTags: pmoTags,
        );

        lineStart = currentIndex + i + 1;
        segmentStart = i + 1;
      }
    }

    // Process inline attributes for remaining content after the last newline
    if (segmentStart < content.length && attributes != null && attributes.isNotEmpty) {
      final segment = content.substring(segmentStart);
      _processInlineAttributes(
        content: segment,
        attributes: attributes,
        currentIndex: currentIndex + segmentStart,
        pmoTags: pmoTags,
      );
    }

    return (
      lineStartIndex: lineStart,
      inCodeBlock: inCodeBlockState,
    );
  }

  /// Processes block-level attributes (headers, lists, blockquotes, code blocks).
  /// Returns the updated [inCodeBlock] state.
  static bool _processBlockAttributes({
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
      pmoTags.add(PmoTag(start: lineStartIndex, end: lineStartIndex, replacement: '```\n'));
      updatedInCodeBlock = true;
    }

    // Exit code block: transition from code-block to non-code-block
    if (!isCodeBlockLine && updatedInCodeBlock) {
      // Add closing fence right after the newline of the previous (last code block) line
      final newlinePosition = currentIndex + charIndex;
      pmoTags
          .add(PmoTag(start: newlinePosition + 1, end: newlinePosition + 1, replacement: '\n```'));
      updatedInCodeBlock = false;
    }

    // Process other block attributes
    if (attributes != null) {
      if (attributes.containsKey('header')) {
        final level = attributes['header'] as int;
        final hashes = '#' * level;
        pmoTags.add(PmoTag(start: lineStartIndex, end: lineStartIndex, replacement: '$hashes '));
      }
      if (attributes.containsKey('list')) {
        final listType = attributes['list'];
        if (listType != null) {
          final marker = listType == 'ordered' ? '1. ' : '- ';
          pmoTags.add(PmoTag(start: lineStartIndex, end: lineStartIndex, replacement: marker));
        }
      }
      if (attributes.containsKey('blockquote')) {
        pmoTags.add(PmoTag(start: lineStartIndex, end: lineStartIndex, replacement: '> '));
      }
    }

    return updatedInCodeBlock;
  }

  /// Processes inline attributes (bold, italic, strike, underline, code, link).
  ///
  /// Formatting is applied in a specific order: code, bold, italic, strike, underline, link.
  /// Code is applied first so other styles wrap the backticks correctly.
  static void _processInlineAttributes({
    required String content,
    required Map<String, dynamic> attributes,
    required int currentIndex,
    required List<PmoTag> pmoTags,
  }) {
    if (content.trim().isEmpty) {
      return; // Skip empty or whitespace-only content
    }

    var replacement = content;
    final hasBold = attributes.containsKey('bold');
    final hasItalic = attributes.containsKey('italic');

    // Apply formatting in order: code, bold, italic, strike, underline, link
    if (attributes.containsKey('code')) {
      replacement = '`$replacement`';
    }

    // Handle bold and italic together (must be before individual checks)
    if (hasBold && hasItalic) {
      replacement = '***$replacement***';
    } else if (hasBold) {
      replacement = '**$replacement**';
    } else if (hasItalic) {
      replacement = '*$replacement*';
    }

    if (attributes.containsKey('strike')) {
      replacement = '~~$replacement~~';
    }
    if (attributes.containsKey('underline')) {
      replacement = '<u>$replacement</u>';
    }
    if (attributes.containsKey('link')) {
      final link = attributes['link'] ?? '';
      replacement = '[$replacement]($link)';
    }

    if (replacement != content) {
      pmoTags.add(
        PmoTag(
          start: currentIndex,
          end: currentIndex + content.length,
          replacement: replacement,
        ),
      );
    }
  }

  /// Creates a PMO tag for an embed placeholder.
  static void _addEmbedPmoTag({
    required int currentIndex,
    required String placeholder,
    required String replacement,
    required List<PmoTag> pmoTags,
  }) {
    pmoTags.add(
      PmoTag(
        start: currentIndex,
        end: currentIndex + placeholder.length,
        replacement: replacement,
      ),
    );
  }

  /// Processes embed data (images, separators, code blocks).
  static String _processEmbed({
    required Map<dynamic, dynamic> data,
    required int currentIndex,
    required List<PmoTag> pmoTags,
  }) {
    if (data.containsKey('text-editor-single-image')) {
      final imageUrl = data['text-editor-single-image'] ?? '';
      const placeholder = ' ';
      final replacement = '![]($imageUrl)';
      _addEmbedPmoTag(
        currentIndex: currentIndex,
        placeholder: placeholder,
        replacement: replacement,
        pmoTags: pmoTags,
      );
      return placeholder;
    }

    if (data.containsKey('text-editor-separator')) {
      const placeholder = '\n';
      const replacement = '\n---\n';
      _addEmbedPmoTag(
        currentIndex: currentIndex,
        placeholder: placeholder,
        replacement: replacement,
        pmoTags: pmoTags,
      );
      return placeholder;
    }

    if (data.containsKey('text-editor-code')) {
      final code = data['text-editor-code'] ?? '';
      const placeholder = '\n';
      final replacement = '\n```\n$code\n```\n';
      _addEmbedPmoTag(
        currentIndex: currentIndex,
        placeholder: placeholder,
        replacement: replacement,
        pmoTags: pmoTags,
      );
      return placeholder;
    }

    // Fallback: empty placeholder if embed type is unknown
    return '';
  }

  /// Parses PMO tags from raw tag list.
  static List<_ParsedPmoTag> _parsePmoTags(List<List<String>> pmoTags) {
    return pmoTags
        .where((tag) => tag.length >= 3 && tag[0] == PmoTag.tagName)
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
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  /// Validates that a PMO tag can be applied at the current position.
  static bool _isValidPmoTag({
    required _ParsedPmoTag tag,
    required int currentPos,
    required int textLength,
  }) {
    return tag.start >= currentPos &&
        tag.start <= textLength &&
        tag.end <= textLength &&
        tag.start <= tag.end;
  }

  /// Maps markdown (via PMO tags) to Delta.
  ///
  /// Used for backward compatibility when reading posts/articles
  /// that have PMO tags but no richText Delta.
  ///
  /// Parameters:
  /// - [plainText]: The plain text content from the event
  /// - [pmoTags]: List of PMO tags in format ['pmo', 'start:end', 'markdown replacement']
  ///
  /// Returns: Delta mapped from the markdown created by applying PMO tags
  static Delta mapMarkdownToDelta(String plainText, List<List<String>> pmoTags) {
    if (pmoTags.isEmpty) {
      return Delta()..insert('$plainText\n');
    }

    final parsedTags = _parsePmoTags(pmoTags);
    final buffer = StringBuffer();
    var currentPos = 0;

    for (final tag in parsedTags) {
      if (!_isValidPmoTag(
        tag: tag,
        currentPos: currentPos,
        textLength: plainText.length,
      )) {
        continue;
      }

      // Write any plain text before this tag (including newlines)
      if (tag.start > currentPos) {
        final textBefore = plainText.substring(currentPos, tag.start);
        // Add two spaces before single newlines to create hard breaks in markdown
        // This ensures line breaks are preserved when converting back to Delta
        final textWithHardBreaks = textBefore.replaceAllMapped(
          RegExp(r'(?<!\n)\n(?!\n)'),
          (match) => '  \n',
        );
        buffer.write(textWithHardBreaks);
      }

      // Write the markdown replacement
      buffer.write(tag.replacement);
      currentPos = tag.end;
    }

    // Write any remaining plain text after the last tag
    if (currentPos < plainText.length) {
      final textAfter = plainText.substring(currentPos);
      // Add two spaces before single newlines to create hard breaks in markdown
      final textWithHardBreaks = textAfter.replaceAllMapped(
        RegExp(r'(?<!\n)\n(?!\n)'),
        (match) => '  \n',
      );
      buffer.write(textWithHardBreaks);
    }

    final markdown = buffer.toString();
    // Ensure the markdown ends with a newline for proper parsing
    final markdownWithNewline = markdown.endsWith('\n') ? markdown : '$markdown\n';
    return markdownToDelta(markdownWithNewline);
  }
}
