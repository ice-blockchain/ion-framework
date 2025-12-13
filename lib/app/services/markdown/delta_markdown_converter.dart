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

  /// Maps a Delta JSON list to [PmoConversionResult] for posts.
  ///
  /// Simplified version that only supports bold and italic formatting.
  /// Skips all block-level markdown (headers, lists, blockquotes, code blocks)
  /// and other inline formatting (code, strike, underline, links).
  static Future<PmoConversionResult> mapDeltaToPmoForPosts(List<dynamic> deltaJson) async {
    return compute(_mapDeltaToPmoForPosts, deltaJson);
  }

  /// Internal static function for use with [compute] for posts.
  static PmoConversionResult _mapDeltaToPmoForPosts(List<dynamic> deltaJson) {
    final delta = Delta.fromJson(deltaJson);
    final buffer = StringBuffer();
    final pmoTags = <PmoTag>[];

    var currentIndex = 0;

    for (final op in delta.operations) {
      if (op.key == 'insert') {
        final data = op.data;
        final attributes = op.attributes;

        if (data is String) {
          // Process inline attributes for posts (only bold and italic)
          if (attributes != null && attributes.isNotEmpty) {
            _processInlineAttributesForPosts(
              content: data,
              attributes: attributes,
              currentIndex: currentIndex,
              pmoTags: pmoTags,
            );
          }

          buffer.write(data);
          currentIndex += data.length;
        } else if (data is Map) {
          // Handle image embeds for posts
          final placeholder = _processEmbedForPosts(
            data: data,
            currentIndex: currentIndex,
            pmoTags: pmoTags,
          );

          buffer.write(placeholder);
          currentIndex += placeholder.length;
        }
      }
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

  /// Processes inline attributes for posts (only bold, italic, and image links).
  ///
  /// Only supports bold and italic formatting, and image links (spaces with link attribute).
  /// Uses HTML tags instead of markdown syntax.
  static void _processInlineAttributesForPosts({
    required String content,
    required Map<String, dynamic> attributes,
    required int currentIndex,
    required List<PmoTag> pmoTags,
  }) {
    final hasLink = attributes.containsKey('link');

    // Handle image links (spaces with link attribute represent images in posts)
    if (hasLink && content.trim().isEmpty) {
      final imageUrl = attributes['link'] ?? '';
      final replacement = '<img src="$imageUrl" />';
      pmoTags.add(
        PmoTag(
          start: currentIndex,
          end: currentIndex + content.length,
          replacement: replacement,
        ),
      );
      return;
    }

    if (content.trim().isEmpty) {
      return; // Skip empty or whitespace-only content without links
    }

    final hasBold = attributes.containsKey('bold');
    final hasItalic = attributes.containsKey('italic');

    // Only process if we have bold or italic
    if (!hasBold && !hasItalic) {
      return;
    }

    var replacement = content;

    // Handle bold and italic together (must be before individual checks)
    // Use HTML tags instead of markdown syntax
    if (hasBold && hasItalic) {
      replacement = '<b><i>$replacement</i></b>';
    } else if (hasBold) {
      replacement = '<b>$replacement</b>';
    } else if (hasItalic) {
      replacement = '<i>$replacement</i>';
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

  /// Processes embed data for posts (only images).
  ///
  /// Only handles image embeds, ignoring other embed types.
  /// Uses HTML img tag instead of markdown syntax.
  static String _processEmbedForPosts({
    required Map<dynamic, dynamic> data,
    required int currentIndex,
    required List<PmoTag> pmoTags,
  }) {
    if (data.containsKey('text-editor-single-image')) {
      final imageUrl = data['text-editor-single-image'] ?? '';
      const placeholder = ' ';
      final replacement = '<img src="$imageUrl" />';
      _addEmbedPmoTag(
        currentIndex: currentIndex,
        placeholder: placeholder,
        replacement: replacement,
        pmoTags: pmoTags,
      );
      return placeholder;
    }

    // Fallback: empty placeholder if embed type is unknown or not supported
    return '';
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

  /// Maps HTML tags (via PMO tags) directly to Delta for posts.
  ///
  /// Converts HTML tags like <b>, <i>, <img> directly to Delta without markdown parsing.
  ///
  /// Parameters:
  /// - [plainText]: The plain text content from the event
  /// - [pmoTags]: List of PMO tags in format ['pmo', 'start:end', 'HTML replacement']
  ///
  /// Returns: Delta mapped from HTML tags in PMO tags
  static Delta mapPmoTagsToDeltaForPosts(String plainText, List<List<String>> pmoTags) {
    if (pmoTags.isEmpty) {
      return Delta()..insert('$plainText\n');
    }

    final parsedTags = _parsePmoTags(pmoTags);
    final delta = Delta();
    var currentPos = 0;

    for (final tag in parsedTags) {
      if (!_isValidPmoTag(
        tag: tag,
        currentPos: currentPos,
        textLength: plainText.length,
      )) {
        continue;
      }

      // Write any plain text before this tag
      if (tag.start > currentPos) {
        final textBefore = plainText.substring(currentPos, tag.start);
        delta.insert(textBefore);
      }

      // Parse HTML replacement and convert to Delta operations
      _parseHtmlReplacementToDelta(tag.replacement, delta);
      currentPos = tag.end;
    }

    // Write any remaining plain text after the last tag
    if (currentPos < plainText.length) {
      final textAfter = plainText.substring(currentPos);
      delta.insert(textAfter);
    }

    // Ensure delta ends with newline
    if (delta.operations.isNotEmpty) {
      final lastOp = delta.operations.last;
      if (lastOp.key == 'insert' && lastOp.data is String) {
        final text = lastOp.data! as String;
        if (!text.endsWith('\n')) {
          delta.insert('\n');
        }
      } else {
        delta.insert('\n');
      }
    }

    return delta;
  }

  /// Parses HTML replacement string and adds corresponding Delta operations.
  ///
  /// Handles <b>, <i>, <b><i>, and <img> tags.
  static void _parseHtmlReplacementToDelta(String replacement, Delta delta) {
    // Match HTML tags: <b>text</b>, <i>text</i>, <b><i>text</i></b>, <img src="url" />
    final boldItalicPattern = RegExp('<b><i>(.*?)</i></b>');
    final boldPattern = RegExp('<b>(.*?)</b>');
    final italicPattern = RegExp('<i>(.*?)</i>');
    final imgPattern = RegExp(r'<img\s+src="([^"]+)"\s*/>');

    // Check for image first
    // In posts, images are stored as links with a space, not as embeds
    final imgMatch = imgPattern.firstMatch(replacement);
    if (imgMatch != null) {
      final imageUrl = imgMatch.group(1) ?? '';
      delta.insert(' ', {'link': imageUrl});
      return;
    }

    // Check for bold+italic
    final boldItalicMatch = boldItalicPattern.firstMatch(replacement);
    if (boldItalicMatch != null) {
      final text = boldItalicMatch.group(1) ?? '';
      delta.insert(text, {'bold': true, 'italic': true});
      return;
    }

    // Check for bold
    final boldMatch = boldPattern.firstMatch(replacement);
    if (boldMatch != null) {
      final text = boldMatch.group(1) ?? '';
      delta.insert(text, {'bold': true});
      return;
    }

    // Check for italic
    final italicMatch = italicPattern.firstMatch(replacement);
    if (italicMatch != null) {
      final text = italicMatch.group(1) ?? '';
      delta.insert(text, {'italic': true});
      return;
    }

    // Fallback: insert as plain text
    delta.insert(replacement);
  }

  /// Maps markdown (via PMO tags) to Delta.
  ///
  /// Used for backward compatibility when reading posts/articles
  /// that have PMO tags but no richText Delta.
  ///
  /// Automatically detects if PMO tags contain HTML (for posts) or markdown (for articles).
  ///
  /// Parameters:
  /// - [plainText]: The plain text content from the event
  /// - [pmoTags]: List of PMO tags in format ['pmo', 'start:end', 'markdown/HTML replacement']
  ///
  /// Returns: Delta mapped from the markdown/HTML created by applying PMO tags
  static Delta mapMarkdownToDelta(String plainText, List<List<String>> pmoTags) {
    // Check if any PMO tag contains HTML tags (for posts) instead of markdown
    final hasHtmlTags = pmoTags.any((tag) {
      if (tag.length < 3 || tag[0] != PmoTag.tagName) return false;
      final replacement = tag[2];
      return replacement.contains(RegExp('<(b|i|img)'));
    });

    if (hasHtmlTags) {
      // Use HTML tag parser for posts
      return mapPmoTagsToDeltaForPosts(plainText, pmoTags);
    }
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
