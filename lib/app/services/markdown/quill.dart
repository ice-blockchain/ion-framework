// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:ion/app/components/text_editor/attributes.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/text_editor_single_image_block/text_editor_single_image_block.dart';
import 'package:ion/app/services/text_parser/model/text_matcher.dart';
import 'package:ion/app/services/text_parser/text_parser.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';

final _mdDocument = md.Document(
  encodeHtml: false,
  extensionSet: md.ExtensionSet.gitHubFlavored,
);

final _mdToDelta = MarkdownToDelta(
  markdownDocument: _mdDocument,
  softLineBreak: true,
  customElementToEmbeddable: {
    'img': (attrs) {
      final imageUrl = attrs['src'] ?? '';
      return TextEditorSingleImageEmbed(imageUrl);
    },
  },
);

Delta plainTextToDelta(String text) {
  final matches = TextParser.allMatchers().parse(text.trim());
  final operations = <Operation>[];

  for (final match in matches) {
    operations.add(
      switch (match.matcher) {
        UrlMatcher() => Operation.insert(match.text, {Attribute.link.key: match.text}),
        HashtagMatcher() =>
          Operation.insert(match.text, {HashtagAttribute.attributeKey: match.text}),
        CashtagMatcher() =>
          Operation.insert(match.text, {CashtagAttribute.attributeKey: match.text}),
        _ => Operation.insert(match.text),
      },
    );
  }

  operations.add(Operation.insert('\n'));

  return Delta.fromOperations(operations);
}

final deltaToMd = DeltaToMarkdown(
  customEmbedHandlers: {
    'text-editor-single-image': (embed, out) {
      final imageUrl = embed.value.data;
      out.write('![image]($imageUrl)');
    },
    'text-editor-separator': (embed, out) {
      out.write('\n---\n');
    },
    'text-editor-code': (embed, out) {
      final content = embed.value.data;
      out.write('\n```\n$content\n```\n');
    },
  },
  visitLineHandleNewLine: (style, out) {
    out.write('\n');
  },
);

String deltaToMarkdown(Delta delta) {
  final processedDelta = Delta();

  for (final op in delta.operations) {
    if (op.key == 'insert') {
      if (op.data is Map) {
        processedDelta.insert(op.data);
      } else if (op.attributes?.containsKey('text-editor-single-image') ?? false) {
        processedDelta.insert({
          'text-editor-single-image': op.attributes!['text-editor-single-image'],
        });
      } else {
        final data = op.data;
        final attributes = op.attributes;

        // Handle underline: markdown doesn't support underline natively,
        // so we need to wrap it in HTML <u> tags
        if (data is String && (attributes?.containsKey('underline') ?? false)) {
          // Check if there are other attributes (bold, italic) that need to be handled
          final hasBold = attributes?.containsKey('bold') ?? false;
          final hasItalic = attributes?.containsKey('italic') ?? false;

          // Build the markdown with underline as HTML <u> tags
          var text = data;

          // Apply bold and italic first (markdown syntax)
          if (hasBold && hasItalic) {
            text = '***$text***';
          } else if (hasBold) {
            text = '**$text**';
          } else if (hasItalic) {
            text = '*$text*';
          }

          // Wrap in <u> tags for underline
          text = '<u>$text</u>';

          // Insert as plain text - the markdown converter should preserve HTML
          processedDelta.insert(text);
        } else {
          processedDelta.insert(op.data, op.attributes);
        }
      }
    }
  }

  final markdown = deltaToMd.convert(processedDelta);

  // Post-process to ensure <u> tags are preserved (not escaped)
  // The markdown converter might escape HTML, so we unescape <u> tags
  final processedMarkdown = markdown.replaceAll(r'\<u\>', '<u>').replaceAll(r'\</u\>', '</u>');

  // Add two spaces before single newlines to create hard breaks in markdown
  // This ensures line breaks are preserved when converting back to Delta
  // We don't modify newlines that already have two spaces, double newlines (paragraphs),
  // or newlines inside code blocks (code blocks already preserve newlines)
  return processedMarkdown.replaceAllMapped(
    RegExp(r'(?<!  )\n(?!\n)(?!```)'),
    (match) {
      // Check if this newline is inside a code block
      final beforeMatch = processedMarkdown.substring(0, match.start);
      final codeBlockOpenCount = beforeMatch.split('```').length - 1;
      // If we have an odd number of ```, we're inside a code block
      if (codeBlockOpenCount.isOdd) {
        return '\n'; // Don't add spaces inside code blocks
      }
      return '  \n';
    },
  );
}

Delta markdownToDelta(String markdown) {
  final delta = _mdToDelta.convert(markdown);
  final processedDelta = Delta();

  for (final op in delta.operations) {
    if (op.key == 'insert' && op.data is Map) {
      final data = op.data! as Map;
      if (data.containsKey('image')) {
        final imageUrl = data['image'] as String;
        processedDelta.insert({
          'text-editor-single-image': imageUrl,
        });
      } else if (data.containsKey('divider')) {
        processedDelta.insert({
          'text-editor-separator': '---',
        });
      } else {
        processedDelta.insert(op.data, _normalizeAttributes(op.attributes));
      }
    } else if (op.key == 'insert' && op.data is String) {
      // Check for HTML <u> tags and convert them to underline attributes
      final text = op.data! as String;
      final attrs = _normalizeAttributes(op.attributes);

      // Pattern to match <u>...</u> tags, including nested markdown formatting
      final underlinePattern = RegExp('<u>(.*?)</u>', dotAll: true);

      if (underlinePattern.hasMatch(text)) {
        // Process text with <u> tags
        var lastEnd = 0;
        final matches = underlinePattern.allMatches(text);

        for (final match in matches) {
          // Add text before the tag
          if (match.start > lastEnd) {
            final beforeText = text.substring(lastEnd, match.start);
            if (beforeText.isNotEmpty) {
              processedDelta.insert(beforeText, attrs);
            }
          }

          // Process the content inside <u> tags
          final underlinedContent = match.group(1) ?? '';

          // Check for markdown formatting inside the <u> tags
          final hasBold = underlinedContent.contains('**');
          final hasItalic = underlinedContent.contains('*') && !hasBold;
          final hasBoldItalic = underlinedContent.contains('***');

          // Extract plain text by removing markdown formatting
          final plainText =
              underlinedContent.replaceAll('***', '').replaceAll('**', '').replaceAll('*', '');

          // Build attributes
          final underlineAttrs = <String, dynamic>{
            'underline': true,
            if (hasBoldItalic || hasBold) 'bold': true,
            if (hasBoldItalic || hasItalic) 'italic': true,
            ...?attrs,
          };

          processedDelta.insert(plainText, underlineAttrs);
          lastEnd = match.end;
        }

        // Add remaining text after last tag
        if (lastEnd < text.length) {
          final afterText = text.substring(lastEnd);
          if (afterText.isNotEmpty) {
            processedDelta.insert(afterText, attrs);
          }
        }
      } else {
        // No underline tags, insert normally with normalized attributes
        processedDelta.insert(op.data, attrs);
      }
    } else {
      processedDelta.insert(op.data, _normalizeAttributes(op.attributes));
    }
  }

  return withFullLinks(processedDelta);
}

/// Normalizes attributes to ensure they use string keys that QuillEditor expects.
/// The markdown_quill package may return attributes in different formats, so we
/// normalize them to ensure consistent handling.
Map<String, dynamic>? _normalizeAttributes(Map<String, dynamic>? attrs) {
  if (attrs == null || attrs.isEmpty) return attrs;

  // Map of alternative keys to normalized keys
  // Handles both string keys ('bold', 'strong', 'italic', 'em') and Attribute object keys
  final keyNormalizations = <String, String>{
    'bold': 'bold',
    'strong': 'bold',
    Attribute.bold.key: 'bold',
    'italic': 'italic',
    'em': 'italic',
    Attribute.italic.key: 'italic',
  };

  final normalized = <String, dynamic>{};

  for (final entry in attrs.entries) {
    final normalizedKey = keyNormalizations[entry.key];

    if (normalizedKey != null) {
      // Normalize bold/italic keys and ensure they're set to true
      normalized[normalizedKey] = true;
    } else {
      // Preserve other attributes as-is
      normalized[entry.key] = entry.value;
    }
  }

  return normalized.isEmpty ? null : normalized;
}

void _processMatches(Operation op, Delta processedDelta) {
  if (op.data is Map) {
    processedDelta.insert(op.data, op.attributes);
    return;
  }

  final textParser = TextParser.tagsMatchers();
  final text = op.data.toString();
  final matches = textParser.parse(text);

  if (matches.isEmpty) {
    processedDelta.insert(op.data, op.attributes);
  } else {
    for (final match in matches) {
      processedDelta.insert(
        match.text,
        {
          ...?op.attributes,
          ...switch (match.matcher) {
            HashtagMatcher() => {HashtagAttribute.attributeKey: match.text},
            CashtagMatcher() => {CashtagAttribute.attributeKey: match.text},
            _ => {},
          },
        },
      );
    }
  }
}

Delta processDelta(Delta delta) {
  final newDelta = Delta();

  for (final op in delta.operations) {
    if (op.data is String && (op.attributes?.containsKey('text-editor-single-image') ?? false)) {
      final imageUrl = op.attributes!['text-editor-single-image'] as String;
      newDelta.insert({'text-editor-single-image': imageUrl});
    } else {
      newDelta.insert(op.data, op.attributes);
    }
  }

  return withFullLinks(newDelta);
}

Delta parseAndConvertDelta(String? deltaContent, String fallbackMarkdown) {
  Delta? delta;

  try {
    if (deltaContent != null) {
      delta = Delta.fromJson(jsonDecode(deltaContent) as List<dynamic>);
      delta = processDelta(delta);
      delta = processDeltaMatches(delta);
    }
  } catch (e) {
    delta = null;
  }

  // Fallback to markdown if delta parsing failed
  return delta ?? markdownToDelta(fallbackMarkdown);
}

Delta processDeltaMatches(Delta delta) {
  final newDelta = Delta();
  for (final op in delta.operations) {
    _processMatches(op, newDelta);
  }
  return newDelta;
}

Delta withFlattenLinks(Delta delta) {
  final out = Delta();
  for (final op in delta.toList()) {
    final href = op.attributes?[Attribute.link.key];
    if (href != null && op.value is String && op.value == href) {
      out.push(Operation.insert(' ', {Attribute.link.key: href}));
    } else {
      out.push(op);
    }
  }
  return out;
}

Delta withFullLinks(Delta delta) {
  final out = Delta();
  for (final op in delta.toList()) {
    final href = op.attributes?[Attribute.link.key];
    if (href != null && op.value is String && op.value == ' ') {
      out.push(Operation.insert(href, {Attribute.link.key: href}));
    } else {
      out.push(op);
    }
  }
  return out;
}
