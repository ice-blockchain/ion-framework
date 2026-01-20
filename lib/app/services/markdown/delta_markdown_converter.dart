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
    final mergedOps = _mergeConsecutiveFormattingOps(delta.operations);

    final buffer = StringBuffer();
    final pmoTags = <PmoTag>[];

    var currentIndex = 0;
    var lineStartIndex = 0;
    var inCodeBlock = false;

    for (final op in mergedOps) {
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

  /// Merges consecutive string operations that have the same formatting attributes.
  /// This prevents splitting bold/italic formatting at hashtag boundaries.
  /// Formatting attributes include: bold, italic, strike, underline, code, link.
  /// Styling attributes (hashtag, cashtag, mention) are preserved but don't prevent merging.
  static List<Operation> _mergeConsecutiveFormattingOps(List<Operation> operations) {
    if (operations.isEmpty) return operations;

    final merged = <Operation>[];
    Operation? pendingOp;

    for (final op in operations) {
      if (op.key != 'insert' || op.data is! String) {
        // Flush pending operation before non-string operations
        if (pendingOp != null) {
          merged.add(pendingOp);
          pendingOp = null;
        }
        merged.add(op);
        continue;
      }

      final opData = op.data! as String;
      final opAttrs = _getFormattingAttributes(op.attributes);

      if (pendingOp == null) {
        pendingOp = op;
      } else {
        final pendingData = pendingOp.data! as String;
        final pendingAttrs = _getFormattingAttributes(pendingOp.attributes);

        // Check if operations can be merged (same formatting attributes)
        if (_areFormattingAttributesEqual(pendingAttrs, opAttrs)) {
          final mergedData = pendingData + opData;
          final mergedAttrs = _mergeAttributes(pendingOp.attributes, op.attributes);
          pendingOp = Operation.insert(mergedData, mergedAttrs);
        } else {
          merged.add(pendingOp);
          pendingOp = op;
        }
      }
    }

    if (pendingOp != null) {
      merged.add(pendingOp);
    }

    return merged;
  }

  /// Extracts formatting attributes from operation attributes, excluding styling-only attributes.
  /// Formatting attributes: bold, italic, strike, underline, code, link
  /// Styling attributes (excluded): hashtag, cashtag, mention
  static Map<String, dynamic>? _getFormattingAttributes(Map<String, dynamic>? attributes) {
    if (attributes == null) return null;

    const formattingKeys = {
      'bold',
      'italic',
      'strike',
      'underline',
      'code',
      'link',
      'header',
      'list',
      'blockquote',
      'code-block',
    };

    final formattingAttrs = <String, dynamic>{};
    for (final entry in attributes.entries) {
      if (formattingKeys.contains(entry.key)) {
        formattingAttrs[entry.key] = entry.value;
      }
    }

    return formattingAttrs.isEmpty ? null : formattingAttrs;
  }

  /// Compares two attribute maps for equality, considering only formatting attributes.
  static bool _areFormattingAttributesEqual(
    Map<String, dynamic>? attrs1,
    Map<String, dynamic>? attrs2,
  ) {
    if (attrs1 == null && attrs2 == null) return true;
    if (attrs1 == null || attrs2 == null) return false;

    final keys1 = attrs1.keys.toSet();
    final keys2 = attrs2.keys.toSet();

    if (keys1.length != keys2.length) return false;

    for (final key in keys1) {
      if (!keys2.contains(key)) return false;
      if (attrs1[key] != attrs2[key]) return false;
    }

    return true;
  }

  /// Merges two attribute maps, preserving all attributes from both.
  /// Formatting attributes should be the same (already checked), so we preserve them.
  /// Styling attributes (hashtag, cashtag, mention) are preserved from both operations.
  static Map<String, dynamic>? _mergeAttributes(
    Map<String, dynamic>? attrs1,
    Map<String, dynamic>? attrs2,
  ) {
    if (attrs1 == null && attrs2 == null) return null;
    if (attrs1 == null) return attrs2;
    if (attrs2 == null) return attrs1;

    // Start with attrs1, then add/override with attrs2
    // Since formatting attributes are the same, this mainly preserves styling attributes
    return {...attrs1, ...attrs2};
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
    // Allow processing links even if content is whitespace-only (needed for media attachments)
    final hasLink = attributes.containsKey('link');
    if (content.trim().isEmpty && !hasLink) {
      return; // Skip empty or whitespace-only content without links
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
    if (hasLink) {
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

    if (data.containsKey('text-editor-ad')) {
      const placeholder = '\n';
      const replacement = '\n--ad--\n';
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
        // But don't add spaces inside code blocks (they already preserve newlines)
        final textWithHardBreaks = textBefore.replaceAllMapped(
          RegExp(r'(?<!\n)\n(?!\n)'),
          (match) {
            // Check if we're inside a code block by looking at the markdown buffer so far
            final markdownSoFar = buffer.toString();
            final codeBlockOpenCount = markdownSoFar.split('```').length - 1;
            // If we have an odd number of ```, we're inside a code block
            if (codeBlockOpenCount.isOdd) {
              return '\n'; // Don't add spaces inside code blocks
            }
            return '  \n';
          },
        );
        buffer.write(textWithHardBreaks);
      }

      // Write the markdown replacement
      // Normalize markdown formatting to ensure proper parsing
      // Remove trailing/leading spaces from italic/bold markers
      final normalizedReplacement = _normalizeMarkdownReplacement(tag.replacement);
      buffer.write(normalizedReplacement);
      currentPos = tag.end;
    }

    // Write any remaining plain text after the last tag
    if (currentPos < plainText.length) {
      final textAfter = plainText.substring(currentPos);
      // Add two spaces before single newlines to create hard breaks in markdown
      // But don't add spaces inside code blocks (they already preserve newlines)
      final textWithHardBreaks = textAfter.replaceAllMapped(
        RegExp(r'(?<!\n)\n(?!\n)'),
        (match) {
          // Check if we're inside a code block by looking at the markdown buffer so far
          final markdownSoFar = buffer.toString();
          final codeBlockOpenCount = markdownSoFar.split('```').length - 1;
          // If we have an odd number of ```, we're inside a code block
          if (codeBlockOpenCount.isOdd) {
            return '\n'; // Don't add spaces inside code blocks
          }
          return '  \n';
        },
      );
      buffer.write(textWithHardBreaks);
    }

    final markdown = buffer.toString();
    // Ensure the markdown ends with a newline for proper parsing
    final markdownWithNewline = markdown.endsWith('\n') ? markdown : '$markdown\n';
    return markdownToDelta(markdownWithNewline);
  }

  /// Normalizes markdown replacement strings to ensure proper parsing.
  /// Removes trailing/leading spaces from italic/bold markers that would
  /// prevent the markdown parser from recognizing them.
  /// Preserves spaces by moving them outside the markers (after closing marker for trailing,
  /// before opening marker for leading).
  /// Process in order: bold+italic first, then bold, then italic to avoid partial matches.
  static String _normalizeMarkdownReplacement(String replacement) {
    // Define patterns in order of specificity (most specific first)
    // Each entry: (pattern, replacement function)
    // Strategy: Move spaces outside markers to preserve them while fixing markdown syntax
    final patterns = <(RegExp, String Function(Match))>[
      // Bold+italic with trailing space: "***text ***" -> "***text*** " (space moved after)
      (
        RegExp(r'\*\*\*([^*]+?)\s+\*\*\*'),
        (Match m) => '***${m.group(1)}*** ',
      ),
      // Bold+italic with leading space: "*** text***" -> " ***text***" (space moved before)
      (
        RegExp(r'\*\*\*\s+([^*]+?)\*\*\*'),
        (Match m) => ' ***${m.group(1)}***',
      ),
      // Bold with trailing space: "**text **" -> "**text** " (space moved after)
      (
        RegExp(r'\*\*([^*]+?)\s+\*\*'),
        (Match m) => '**${m.group(1)}** ',
      ),
      // Bold with leading space: "** text**" -> " **text**" (space moved before)
      (
        RegExp(r'\*\*\s+([^*]+?)\*\*'),
        (Match m) => ' **${m.group(1)}**',
      ),
      // Italic with trailing space: "*text *" -> "*text* " (space moved after)
      (
        RegExp(r'(?<!\*)\*([^*]+?)\s+\*(?!\*)'),
        (Match m) => '*${m.group(1)}* ',
      ),
      // Italic with leading space: "* text*" -> " *text*" (space moved before)
      (
        RegExp(r'(?<!\*)\*\s+([^*]+?)\*(?!\*)'),
        (Match m) => ' *${m.group(1)}*',
      ),
    ];

    // Apply all patterns in sequence using a local variable
    var normalized = replacement;
    for (final (pattern, replacer) in patterns) {
      normalized = normalized.replaceAllMapped(pattern, replacer);
    }

    return normalized;
  }
}
