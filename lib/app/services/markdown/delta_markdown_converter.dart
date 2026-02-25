// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/foundation.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:ion/app/components/text_editor/attributes.dart';
import 'package:ion/app/features/ion_connect/model/pmo_tag.f.dart';
import 'package:ion/app/services/markdown/quill.dart';

typedef _ParsedPmoTag = ({int start, int end, String replacement});

typedef _CashtagExtraction = ({
  int start,
  int end,
  String ticker,
  String? externalAddress,
  String? coinId,
});

const _xCashtagTicker = 'X';
const _xStatusUrlPrefix = 'https://x.com/i/status/';
final _xStatusIdPattern = RegExp(r'^\d{10,25}$');

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
    var orderedListIndex = 0;

    for (final op in mergedOps) {
      if (op.key == 'insert') {
        final data = op.data;
        final attributes = op.attributes;

        if (data is String) {
          final trimmedDataLeft = data.trimLeft();

          // For mentions, use the bech32 encoded value instead of display text.
          // For cashtags with coinId, use the coinId.
          final hasMentionAttr = attributes != null &&
              attributes.containsKey('mention') &&
              trimmedDataLeft.startsWith('@');
          final hasCashtagCoinId =
              _hasCashtagCoinId(attributes) && trimmedDataLeft.startsWith(r'$');

          final contentToWrite = hasMentionAttr
              ? (attributes['mention'] as String? ?? data)
              : hasCashtagCoinId
                  ? (attributes![CashtagCoinIdAttribute.attributeKey] as String)
                  : data;

          final result = _processStringContent(
            content: contentToWrite,
            originalContent: data,
            attributes: attributes,
            currentIndex: currentIndex,
            lineStartIndex: lineStartIndex,
            inCodeBlock: inCodeBlock,
            orderedListIndex: orderedListIndex,
            pmoTags: pmoTags,
          );

          buffer.write(contentToWrite);
          currentIndex += contentToWrite.length;
          lineStartIndex = result.lineStartIndex;
          inCodeBlock = result.inCodeBlock;
          orderedListIndex = result.orderedListIndex;
        } else if (data is Map) {
          final placeholder = _processEmbed(
            data: data,
            currentIndex: currentIndex,
            pmoTags: pmoTags,
          );

          buffer.write(placeholder);
          currentIndex += placeholder.length;
          lineStartIndex = currentIndex;
          orderedListIndex = 0;
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
  /// Cashtags with showMarketCap require exact matching (they have identity via externalAddress).
  /// Hashtags don't prevent merging.
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

    // Cashtags with showMarketCap or coinId have identity — don't merge across boundaries
    bool conflictsOnKey(String key, bool Function(Map<String, dynamic>?) hasIt) {
      final has1 = hasIt(attrs1);
      final has2 = hasIt(attrs2);
      if (!has1 && !has2) return false;
      if (has1 != has2) return true;
      return attrs1?[key] != attrs2?[key];
    }

    if (conflictsOnKey(CashtagAttribute.attributeKey, _hasCashtagWithMarketCap)) return false;
    if (conflictsOnKey(CashtagCoinIdAttribute.attributeKey, _hasCashtagCoinId)) return false;

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
    int orderedListIndex,
  }) _processStringContent({
    required String content,
    required String originalContent,
    required Map<String, dynamic>? attributes,
    required int currentIndex,
    required int lineStartIndex,
    required bool inCodeBlock,
    required int orderedListIndex,
    required List<PmoTag> pmoTags,
  }) {
    var lineStart = lineStartIndex;
    var inCodeBlockState = inCodeBlock;
    var currentOrderedListIndex = orderedListIndex;
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

        final blockResult = _processBlockAttributes(
          attributes: attributes,
          lineStartIndex: lineStart,
          currentIndex: currentIndex,
          charIndex: i,
          inCodeBlock: inCodeBlockState,
          orderedListIndex: currentOrderedListIndex,
          pmoTags: pmoTags,
        );
        inCodeBlockState = blockResult.inCodeBlock;
        currentOrderedListIndex = blockResult.nextOrderedListIndex;

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
      orderedListIndex: currentOrderedListIndex,
    );
  }

  /// Processes block-level attributes (headers, lists, blockquotes, code blocks).
  /// Returns the updated [inCodeBlock] state and [nextOrderedListIndex] for ordered list numbering.
  static ({bool inCodeBlock, int nextOrderedListIndex}) _processBlockAttributes({
    required Map<String, dynamic>? attributes,
    required int lineStartIndex,
    required int currentIndex,
    required int charIndex,
    required bool inCodeBlock,
    required int orderedListIndex,
    required List<PmoTag> pmoTags,
  }) {
    var updatedInCodeBlock = inCodeBlock;
    var nextOrderedListIndex = 0;

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
          if (listType == 'ordered') {
            nextOrderedListIndex = orderedListIndex + 1;
            final marker = '$nextOrderedListIndex. ';
            pmoTags.add(PmoTag(start: lineStartIndex, end: lineStartIndex, replacement: marker));
          } else {
            pmoTags.add(PmoTag(start: lineStartIndex, end: lineStartIndex, replacement: '- '));
          }
        }
      }
      if (attributes.containsKey('blockquote')) {
        pmoTags.add(PmoTag(start: lineStartIndex, end: lineStartIndex, replacement: '> '));
      }
    }

    return (inCodeBlock: updatedInCodeBlock, nextOrderedListIndex: nextOrderedListIndex);
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
    final trimmedOriginalLeft = originalContent.trimLeft();

    // Allow processing links even if content is whitespace-only (needed for media attachments)
    final hasLink = attributes.containsKey('link');
    final hasMention = attributes.containsKey('mention') && trimmedOriginalLeft.startsWith('@');
    final cashtagAttrValue = attributes[CashtagAttribute.attributeKey];
    final hasValidCashtagExternalAddress = cashtagAttrValue is String &&
        cashtagAttrValue.trim().isNotEmpty &&
        cashtagAttrValue.trim() != r'$';
    final hasCashtag = attributes[CashtagAttribute.showMarketCapKey] == true &&
        hasValidCashtagExternalAddress &&
        trimmedOriginalLeft.startsWith(r'$');
    final hasCashtagCoinId = _hasCashtagCoinId(attributes) && trimmedOriginalLeft.startsWith(r'$');

    if (content.trim().isEmpty && !hasLink && !hasMention && !hasCashtag && !hasCashtagCoinId) {
      return;
    }

    var replacement = content;
    final hasBold = attributes.containsKey('bold');
    final hasItalic = attributes.containsKey('italic');
    final skipInlineStyles = hasLink || hasMention || hasCashtag || hasCashtagCoinId;

    if (hasMention) {
      final encodedRef = content;
      replacement = '[$originalContent]($encodedRef)';
    }

    if (hasCashtag && !hasMention) {
      final externalAddress = cashtagAttrValue.trim();
      final displayCashtag = RegExp(r'\$[^\s]+').firstMatch(originalContent)?.group(0);
      if (displayCashtag != null && displayCashtag.isNotEmpty) {
        final pmoLinkTarget = _toCashtagPmoLinkTarget(
          displayCashtag: displayCashtag,
          externalAddress: externalAddress,
        );
        replacement = '[$displayCashtag]($pmoLinkTarget)';
      }
    }

    if (hasCashtagCoinId && !hasCashtag && !hasMention) {
      replacement = '[$originalContent]($content)';
    }

    if (!skipInlineStyles) {
      if (attributes.containsKey('code')) {
        replacement = '`$replacement`';
      }

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
    }

    if (hasLink) {
      final link = attributes['link'] ?? '';
      replacement = '[$originalContent]($link)';
    }

    if (skipInlineStyles) {
      if (attributes.containsKey('code')) {
        replacement = '`$replacement`';
      }

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
    final deltaWithMentions = _addMentionAttributes(delta, mentionExtractions);

    // Extract cashtag addresses from PMO tags and add cashtag attributes
    final cashtagExtractions = _extractCashtagAddresses(plainText, parsedTags);
    return _addCashtagAttributes(deltaWithMentions, cashtagExtractions);
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

  /// Extracts cashtag data from PMO tags.
  ///
  /// Identifies PMO replacements matching the pattern `[$TICKER](value)` where
  /// value is either an externalAddress, an X status URL for `$X` tokens,
  /// or a bech32-encoded coin ID (`ncoin1...`).
  static List<_CashtagExtraction> _extractCashtagAddresses(
    String plainText,
    List<_ParsedPmoTag> pmoTags,
  ) {
    final extractions = <_CashtagExtraction>[];
    final cashtagPmoPattern = RegExp(r'^\[\$([^\]]+)\]\(([^)]+)\)$');

    for (final tag in pmoTags) {
      final match = cashtagPmoPattern.firstMatch(tag.replacement);
      if (match != null) {
        final ticker = match.group(1)!;
        final rawValue = match.group(2)!;
        final value = _normalizeCashtagPmoValue(ticker: ticker, value: rawValue);
        final isCoinId = value.startsWith('ncoin1');
        extractions.add(
          (
            start: tag.start,
            end: tag.end,
            ticker: ticker,
            externalAddress: isCoinId ? null : value,
            coinId: isCoinId ? value : null,
          ),
        );
      }
    }

    return extractions;
  }

  /// Adds mention attributes to Delta operations based on extracted mentions.
  static Delta _addMentionAttributes(
    Delta delta,
    List<({int start, int end, String bech32Value})> mentions,
  ) {
    return _addAttributesAtPositions(
      delta,
      mentions.map((m) => (start: m.start, end: m.end, expectedText: m.bech32Value)).toList(),
      (expectedText, existingAttrs) => {...?existingAttrs, 'mention': expectedText},
    );
  }

  /// Adds cashtag attributes to Delta operations based on extracted cashtag data.
  ///
  /// For tokenized coins (externalAddress): sets `{cashtag: externalAddress, showMarketCap: true}`.
  /// For non-tokenized coins (coinId): sets `{cashtagCoinId: coinId}`.
  static Delta _addCashtagAttributes(Delta delta, List<_CashtagExtraction> cashtags) {
    // Split into two groups and process separately with the shared helper.
    final externalAddressEntries = cashtags.where((ct) => ct.externalAddress != null).toList();
    final coinIdEntries = cashtags.where((ct) => ct.coinId != null).toList();

    final withExternalAddresses = _addAttributesAtPositions(
      delta,
      externalAddressEntries
          .map((ct) => (start: ct.start, end: ct.end, expectedText: ct.externalAddress!))
          .toList(),
      (expectedText, existingAttrs) => {
        ...?existingAttrs,
        CashtagAttribute.attributeKey: expectedText,
        CashtagAttribute.showMarketCapKey: true,
      },
    );

    return _addAttributesAtPositions(
      withExternalAddresses,
      coinIdEntries.map((ct) => (start: ct.start, end: ct.end, expectedText: ct.coinId!)).toList(),
      (expectedText, existingAttrs) => {
        ...?existingAttrs,
        CashtagCoinIdAttribute.attributeKey: expectedText,
      },
    );
  }

  /// Splits Delta operations at the given positions and applies attributes via [buildAttrs].
  ///
  /// Each entry in [positions] specifies a region in the Delta's text where the
  /// [expectedText] should be found. If the text matches, [buildAttrs] is called
  /// to produce the attributes for that segment; otherwise the text is kept as-is.
  static Delta _addAttributesAtPositions(
    Delta delta,
    List<({int start, int end, String expectedText})> positions,
    Map<String, dynamic> Function(String expectedText, Map<String, dynamic>? existingAttrs)
        buildAttrs,
  ) {
    if (positions.isEmpty) {
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

      final opPositions = positions.where((p) => p.start >= opStart && p.end <= opEnd).toList()
        ..sort((a, b) => a.start.compareTo(b.start));

      if (opPositions.isEmpty) {
        newDelta.insert(text, op.attributes);
      } else {
        var cursor = 0;
        for (final pos in opPositions) {
          final startInOp = pos.start - opStart;
          final endInOp = pos.end - opStart;
          if (startInOp > cursor) {
            newDelta.insert(text.substring(cursor, startInOp), op.attributes);
          }
          final segment = text.substring(startInOp, endInOp);
          if (segment == pos.expectedText) {
            newDelta.insert(segment, buildAttrs(pos.expectedText, op.attributes));
          } else {
            newDelta.insert(segment, op.attributes);
          }
          cursor = endInOp;
        }
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

  static bool _hasCashtagCoinId(Map<String, dynamic>? attrs) {
    final v = attrs?[CashtagCoinIdAttribute.attributeKey];
    return v is String && v.isNotEmpty;
  }

  static bool _hasCashtagWithMarketCap(Map<String, dynamic>? attrs) =>
      attrs?[CashtagAttribute.showMarketCapKey] == true &&
      attrs?[CashtagAttribute.attributeKey] is String &&
      (attrs?[CashtagAttribute.attributeKey] as String).trim().isNotEmpty &&
      (attrs?[CashtagAttribute.attributeKey] as String).trim() != r'$';

  static String _toCashtagPmoLinkTarget({
    required String displayCashtag,
    required String externalAddress,
  }) {
    final shouldUseXStatusUrl = _isXCashtag(displayCashtag) || _isXStatusId(externalAddress);
    if (!shouldUseXStatusUrl) {
      return externalAddress;
    }

    if (_extractXStatusId(externalAddress) != null) {
      return externalAddress;
    }

    return '$_xStatusUrlPrefix$externalAddress';
  }

  static String _normalizeCashtagPmoValue({required String ticker, required String value}) {
    if (ticker.toUpperCase() == _xCashtagTicker) {
      return _extractXStatusId(value) ?? value;
    }

    return _extractXStatusId(value) ?? value;
  }

  static bool _isXCashtag(String displayCashtag) =>
      displayCashtag.replaceFirst(r'$', '').toUpperCase() == _xCashtagTicker;

  static bool _isXStatusId(String value) => _xStatusIdPattern.hasMatch(value);

  static String? _extractXStatusId(String value) {
    if (!value.startsWith(_xStatusUrlPrefix)) {
      return null;
    }

    final statusId = value.substring(_xStatusUrlPrefix.length);
    return statusId.isEmpty ? null : statusId;
  }
}
