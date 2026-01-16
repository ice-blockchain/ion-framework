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
          // For mentions, use the bech32 encoded value instead of display text
          final contentToWrite = (attributes != null && attributes.containsKey('mention'))
              ? (attributes['mention'] as String? ?? data)
              : data;

          final result = _processStringContent(
            content: contentToWrite,
            originalContent: data,
            attributes: attributes,
            currentIndex: currentIndex,
            lineStartIndex: lineStartIndex,
            inCodeBlock: inCodeBlock,
            pmoTags: pmoTags,
          );

          buffer.write(contentToWrite);
          currentIndex += contentToWrite.length;
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
  /// Styling attributes (hashtag, cashtag, mention) are NOT merged to preserve boundaries.
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

        // Check if operations can be merged:
        // 1. Must have same formatting attributes (bold, italic, etc.)
        // 2. Hashtags and cashtags don't prevent merging (they can be inside formatted text)
        // 3. Mentions MUST have matching boundaries (they're interactive elements)
        final canMerge = _areFormattingAttributesEqual(pendingAttrs, opAttrs) &&
            _canMergeStylingAttributes(pendingOp.attributes, op.attributes);

        if (canMerge) {
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

  /// Determines if two operations can be merged based on their styling attributes.
  /// Mentions require exact matching (both present or both absent with same value).
  /// Hashtags and cashtags don't prevent merging.
  static bool _canMergeStylingAttributes(
    Map<String, dynamic>? attrs1,
    Map<String, dynamic>? attrs2,
  ) {
    final mention1 = attrs1?['mention'];
    final mention2 = attrs2?['mention'];

    // If both have mentions, they must match exactly
    if (mention1 != null && mention2 != null) {
      return mention1 == mention2;
    }

    // If only one has a mention, they can't be merged
    if (mention1 != null || mention2 != null) {
      return false;
    }

    // Neither has mention, they can be merged (hashtags/cashtags don't matter)
    return true;
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
    required String originalContent,
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
          final originalSegment = originalContent.substring(segmentStart, i);
          _processInlineAttributes(
            content: segment,
            originalContent: originalSegment,
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
      final originalSegment = originalContent.substring(segmentStart);
      _processInlineAttributes(
        content: segment,
        originalContent: originalSegment,
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

  /// Processes inline attributes (bold, italic, strike, underline, code, link, mention).
  ///
  /// Formatting is applied in a specific order: code, bold, italic, strike, underline, link.
  /// Code is applied first so other styles wrap the backticks correctly.
  /// Mentions are formatted as [@username](encoded_reference).
  static void _processInlineAttributes({
    required String content,
    required String originalContent,
    required Map<String, dynamic> attributes,
    required int currentIndex,
    required List<PmoTag> pmoTags,
  }) {
    // Allow processing links even if content is whitespace-only (needed for media attachments)
    final hasLink = attributes.containsKey('link');
    final hasMention = attributes.containsKey('mention');
    if (content.trim().isEmpty && !hasLink && !hasMention) {
      return; // Skip empty or whitespace-only content without links or mentions
    }

    var replacement = content;
    final hasBold = attributes.containsKey('bold');
    final hasItalic = attributes.containsKey('italic');

    // Handle mentions first (format: [@username](encoded_ref))
    // Use originalContent for the display text (e.g., @username)
    if (hasMention) {
      final encodedRef = content; // content is already the encoded reference
      replacement = '[$originalContent]($encodedRef)';
    }

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

    // First, extract bech32 mentions to add attributes later
    final mentionExtractions = _extractBech32Mentions(plainText);

    // Parse and process PMO tags
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
    final delta = markdownToDelta(markdownWithNewline);

    // Now add mention attributes to the Delta for the extracted mentions
    return _addMentionAttributes(delta, mentionExtractions);
  }

  /// Extracts bech32 encoded mentions from plain text.
  ///
  /// Returns a list of extractions with start/end positions and bech32 value.
  static List<({int start, int end, String bech32Value})> _extractBech32Mentions(String text) {
    final extractions = <({int start, int end, String bech32Value})>[];

    // Match ion: or nostr: prefixed bech32 values (nprofile, npub, etc.)
    final bech32Pattern = RegExp('(?:ion:|nostr:)?n(?:profile|pub)[a-z0-9]+');

    for (final match in bech32Pattern.allMatches(text)) {
      final bech32Value = match.group(0)!;

      extractions.add(
        (
          start: match.start,
          end: match.end,
          bech32Value: bech32Value,
        ),
      );
    }

    return extractions;
  }

  /// Adds mention attributes to Delta operations based on extracted mentions.
  ///
  /// This processes the Delta to find bech32 values and adds mention attributes.
  /// The bech32 values remain in the text and will be replaced with @username
  /// by a higher-level function that has access to user metadata.
  static Delta _addMentionAttributes(
    Delta delta,
    List<({int start, int end, String bech32Value})> mentions,
  ) {
    if (mentions.isEmpty) {
      return delta;
    }

    final newDelta = Delta();
    var textPosition = 0;

    for (final op in delta.operations) {
      if (op.data is! String) {
        newDelta.insert(op.data, op.attributes);
        continue;
      }

      final text = op.data! as String;
      final opStart = textPosition;
      final opEnd = textPosition + text.length;

      // Collect all mentions that are entirely within this operation
      final opMentions = mentions
          .where((mention) => mention.start >= opStart && mention.end <= opEnd)
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));
      if (opMentions.isEmpty) {
        // No mentions in this operation: keep it as-is
        newDelta.insert(text, op.attributes);
      } else {
        var cursor = 0;
        for (final mention in opMentions) {
          final mentionStartInOp = mention.start - opStart;
          final mentionEndInOp = mention.end - opStart;
          // Insert text before the mention, if any
          if (mentionStartInOp > cursor) {
            newDelta.insert(
              text.substring(cursor, mentionStartInOp),
              op.attributes,
            );
          }
          // Extract the mention text from this operation
          final mentionText = text.substring(mentionStartInOp, mentionEndInOp);
          // Verify the extracted text matches the bech32 value
          if (mentionText == mention.bech32Value) {
            // Mention with attribute
            final attrs = {
              ...?op.attributes,
              'mention': mention.bech32Value,
            };
            newDelta.insert(mentionText, attrs);
          } else {
            // If the text does not match, fall back to plain text
            newDelta.insert(mentionText, op.attributes);
          }
          cursor = mentionEndInOp;
        }
        // Insert any remaining text after the last mention
        if (cursor < text.length) {
          newDelta.insert(text.substring(cursor), op.attributes);
        }
      }
      
      textPosition = opEnd;
    }

    return newDelta;
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
