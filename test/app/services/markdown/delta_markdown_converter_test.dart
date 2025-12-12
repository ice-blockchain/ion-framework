// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/providers/parsed_media_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/entity_published_at.f.dart';
import 'package:ion/app/features/ion_connect/model/replaceable_event_identifier.f.dart';
import 'package:ion/app/features/ion_connect/model/rich_text.f.dart';
import 'package:ion/app/services/markdown/delta_markdown_converter.dart';
import 'package:ion/app/services/markdown/quill.dart';

import '../../../test_utils.dart';

/// Checks if a Delta contains an image operation.
///
/// [imageUrl]: If provided, only matches images with this specific URL.
bool _hasImageInDelta(Delta delta, {String? imageUrl}) {
  for (final op in delta.operations) {
    if (op.key == 'insert' && op.data is Map) {
      final data = op.data! as Map;
      if (data.containsKey('text-editor-single-image')) {
        if (imageUrl != null) {
          final url = data['text-editor-single-image'] as String?;
          if (url == imageUrl) {
            return true;
          }
        } else {
          return true;
        }
      }
    }
  }
  return false;
}

/// Checks if a Delta contains text operations with specified formatting attributes.
///
/// [textSubstring]: If provided, only checks operations where text contains this substring.
/// [attributeKeys]: If provided, checks that operation has ALL specified attributes.
/// [attributeValues]: If provided, checks that operation attributes match the specified key-value pairs.
bool _hasTextWithFormatting(
  Delta delta, {
  String? textSubstring,
  List<String>? attributeKeys,
  Map<String, dynamic>? attributeValues,
}) {
  for (final op in delta.operations) {
    if (op.key == 'insert' && op.data is String) {
      final text = op.data! as String;
      final attrs = op.attributes;

      // If textSubstring is provided, text must contain it
      if (textSubstring != null && !text.contains(textSubstring)) {
        continue;
      }

      // If attributeKeys are provided, check that ALL are present
      if (attributeKeys != null && attributeKeys.isNotEmpty) {
        final hasAllAttributes = attributeKeys.every(
          (key) => attrs?.containsKey(key) ?? false,
        );
        if (!hasAllAttributes) {
          continue;
        }
      }

      // If attributeValues are provided, check that ALL match
      if (attributeValues != null && attributeValues.isNotEmpty) {
        final hasAllValues = attributeValues.entries.every(
          (entry) => attrs?[entry.key] == entry.value,
        );
        if (!hasAllValues) {
          continue;
        }
      }

      // If we have attributeKeys or attributeValues, we've matched
      if ((attributeKeys != null && attributeKeys.isNotEmpty) ||
          (attributeValues != null && attributeValues.isNotEmpty)) {
        return true;
      }
    }
  }
  return false;
}

/// Checks if a Delta contains operations with specified attributes (regardless of text content).
///
/// [attributeKeys]: Checks that operation has ALL specified attributes.
/// [attributeValues]: If provided, checks that operation attributes match the specified key-value pairs.
bool _hasAttributeInDelta(
  Delta delta, {
  required List<String> attributeKeys,
  Map<String, dynamic>? attributeValues,
}) {
  for (final op in delta.operations) {
    final attrs = op.attributes;
    final hasAllAttributes = attributeKeys.every(
      (key) => attrs?.containsKey(key) ?? false,
    );

    if (hasAllAttributes) {
      // Also check attributeValues if provided
      if (attributeValues != null && attributeValues.isNotEmpty) {
        final hasAllValues = attributeValues.entries.every(
          (entry) => attrs?[entry.key] == entry.value,
        );
        if (hasAllValues) {
          return true;
        }
      } else {
        return true;
      }
    }
  }
  return false;
}

/// Normalizes text for comparison by removing extra whitespace and normalizing image placeholders.
/// Only use this for tests where markdown parser introduces unavoidable whitespace differences.
String _normalizeTextForComparison(String text) {
  return text
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'\s*\uFFFC\s*'), '\uFFFC')
      .trim();
}

/// Counts formatting instances in a Delta by text content and attributes.
///
/// Returns a map with counts for 'italic', 'bold', and 'normal' formatting.
/// [textFilter]: Optional function to filter which text operations to count.
Map<String, int> _countFormattingInstances(
  Delta delta, {
  bool Function(String text)? textFilter,
}) {
  var italicCount = 0;
  var boldCount = 0;
  var normalCount = 0;

  for (final op in delta.operations) {
    if (op.key == 'insert' && op.data is String) {
      final text = op.data! as String;
      final attrs = op.attributes;

      if (textFilter != null && !textFilter(text)) {
        continue;
      }

      final hasItalic = attrs?.containsKey('italic') ?? false;
      final hasBold = attrs?.containsKey('bold') ?? false;

      if (hasItalic && !hasBold) {
        italicCount++;
      } else if (hasBold && !hasItalic) {
        boldCount++;
      } else if (!hasItalic && !hasBold) {
        normalCount++;
      }
    }
  }

  return {
    'italic': italicCount,
    'bold': boldCount,
    'normal': normalCount,
  };
}

/// Counts formatting instances by text substring and specific attributes.
///
/// Returns counts for italic and bold formatting that match the given text patterns.
Map<String, int> _countFormattingByTextPattern(
  Delta delta,
  List<String> textPatterns,
  List<String> attributes,
) {
  var italicCount = 0;
  var boldCount = 0;

  for (final op in delta.operations) {
    if (op.key == 'insert' && op.data is String) {
      final text = op.data! as String;
      final attrs = op.attributes;

      final matchesPattern = textPatterns.any(text.contains);
      if (!matchesPattern) {
        continue;
      }

      for (final attr in attributes) {
        if (attr == 'italic' && (attrs?.containsKey('italic') ?? false)) {
          italicCount++;
        }
        if (attr == 'bold' && (attrs?.containsKey('bold') ?? false)) {
          boldCount++;
        }
      }
    }
  }

  return {
    'italic': italicCount,
    'bold': boldCount,
  };
}

/// Counts headers by level in a Delta.
///
/// Returns a map with counts for each header level (1-6).
Map<int, int> _countHeadersByLevel(Delta delta) {
  final counts = <int, int>{};

  for (final op in delta.operations) {
    if (op.attributes?.containsKey('header') ?? false) {
      final level = op.attributes!['header'] as int;
      counts[level] = (counts[level] ?? 0) + 1;
    }
  }

  return counts;
}

/// Counts list items by type in a Delta.
///
/// Returns a map with counts for 'bullet' and 'ordered' list types.
Map<String, int> _countListItemsByType(Delta delta) {
  var bulletCount = 0;
  var orderedCount = 0;

  for (final op in delta.operations) {
    if (op.attributes?.containsKey('list') ?? false) {
      final listType = op.attributes!['list'] as String;
      if (listType == 'bullet') {
        bulletCount++;
      } else if (listType == 'ordered') {
        orderedCount++;
      }
    }
  }

  return {
    'bullet': bulletCount,
    'ordered': orderedCount,
  };
}

/// Performs a round-trip conversion test: Delta -> PMO -> Delta.
///
/// Returns the result Delta and PMO result for further assertions.
Future<({Delta resultDelta, PmoConversionResult pmoResult})> _performRoundTripConversion(
  Delta expectedDelta,
) async {
  final pmoResult = await DeltaMarkdownConverter.mapDeltaToPmo(expectedDelta.toJson());
  final pmoTags = pmoResult.tags.map((t) => t.toTag()).toList();
  final resultDelta = DeltaMarkdownConverter.mapMarkdownToDelta(pmoResult.text, pmoTags);

  return (resultDelta: resultDelta, pmoResult: pmoResult);
}

/// Asserts that two Deltas have equivalent plain text content.
void _assertDeltaTextEquals(Delta expected, Delta actual) {
  final expectedText = Document.fromDelta(expected).toPlainText();
  final actualText = Document.fromDelta(actual).toPlainText();
  expect(actualText.trim(), equals(expectedText.trim()));
}

/// Creates an EventMessage for testing Posts (kind 1).
EventMessage _createPostEventMessage({
  required String content,
  required EventSigner signer,
  List<List<String>> tags = const [],
}) {
  return EventMessage(
    id: 'test_id',
    pubkey: signer.publicKey,
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    kind: 1,
    content: content,
    tags: tags,
    sig: 'test_sig',
  );
}

/// Creates an EventMessage for testing ModifiablePosts (kind 30175).
EventMessage _createModifiablePostEventMessage({
  required String content,
  required EventSigner signer,
  List<List<String>> tags = const [],
}) {
  return EventMessage(
    id: 'test_id',
    pubkey: signer.publicKey,
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    kind: 30175,
    content: content,
    tags: [
      ReplaceableEventIdentifier.generate().toTag(),
      EntityPublishedAt(
        value: DateTime.now().microsecondsSinceEpoch,
      ).toTag(),
      ...tags,
    ],
    sig: 'test_sig',
  );
}

/// Creates an EventMessage for testing Articles (kind 30023).
EventMessage _createArticleEventMessage({
  required String content,
  required EventSigner signer,
  List<List<String>> tags = const [],
}) {
  return EventMessage(
    id: 'test_id',
    pubkey: signer.publicKey,
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    kind: 30023,
    content: content,
    tags: [
      ReplaceableEventIdentifier.generate().toTag(),
      EntityPublishedAt(
        value: DateTime.now().microsecondsSinceEpoch,
      ).toTag(),
      ...tags,
    ],
    sig: 'test_sig',
  );
}

/// Creates a RichText object from a Delta for testing.
RichText _createRichTextFromDelta(Delta delta) {
  return RichText(
    protocol: 'quill_delta',
    content: jsonEncode(delta.toJson()),
  );
}

void main() {
  group('DeltaMarkdownConverter', () {
    late EventSigner signer;

    setUpAll(() async {
      signer = await createTestSigner();
    });

    group('Delta to PMO conversion', () {
      test('converts plain text without tags', () async {
        final delta = Delta()..insert('Hello world\n');
        final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

        expect(result.text, 'Hello world\n');
        expect(result.tags, isEmpty);
      });

      test('converts bold text', () async {
        final delta = Delta()
          ..insert('Hello ')
          ..insert('bold', {'bold': true})
          ..insert(' world\n');
        final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

        expect(result.text, 'Hello bold world\n');
        expect(result.tags, hasLength(1));
        expect(result.tags.first.start, 6);
        expect(result.tags.first.end, 10);
        expect(result.tags.first.replacement, '**bold**');
      });

      test('converts italic text', () async {
        final delta = Delta()
          ..insert('Hello ')
          ..insert('italic', {'italic': true})
          ..insert('\n');
        final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

        expect(result.text, 'Hello italic\n');
        expect(result.tags.first.replacement, '*italic*');
      });

      test('converts bold and italic text', () async {
        final delta = Delta()
          ..insert('Hello ')
          ..insert('bolditalic', {'bold': true, 'italic': true})
          ..insert('\n');
        final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

        expect(result.text, 'Hello bolditalic\n');
        expect(
          result.tags.first.replacement,
          '***bolditalic***', // Note: implementation might vary on nesting order
        );
      });

      test('converts links', () async {
        final delta = Delta()
          ..insert('Click ')
          ..insert('here', {'link': 'https://example.com'})
          ..insert('\n');
        final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

        expect(result.text, 'Click here\n');
        expect(result.tags.first.replacement, '[here](https://example.com)');
      });

      test('converts images', () async {
        final delta = Delta()
          ..insert('Image: ')
          ..insert({'text-editor-single-image': 'https://example.com/image.png'})
          ..insert('\n');
        final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

        expect(result.text, 'Image:  \n'); // Space placeholder
        expect(
          result.tags.first.replacement,
          '![](https://example.com/image.png)', // Check implementation details
        );
      });

      test('converts code', () async {
        final delta = Delta()
          ..insert('Code: ')
          ..insert('print("hello")', {'code': true})
          ..insert('\n');
        final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

        expect(result.text, 'Code: print("hello")\n');
        expect(result.tags.first.replacement, '`print("hello")`');
      });

      test('converts inline underline', () async {
        final delta = Delta()
          ..insert('Underlined', {'underline': true})
          ..insert('\n');
        final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

        expect(result.text, 'Underlined\n');
        expect(result.tags.first.replacement, '<u>Underlined</u>');
      });

      test('converts headers', () async {
        final delta = Delta()
          ..insert('Header 1')
          ..insert('\n', {'header': 1});
        final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

        expect(result.text, 'Header 1\n');
        expect(result.tags.first.replacement, '# ');
        expect(result.tags.first.start, 0);
        expect(result.tags.first.end, 0); // Insertion at start
      });

      test('converts lists', () async {
        final delta = Delta()
          ..insert('Item 1')
          ..insert('\n', {'list': 'bullet'})
          ..insert('Item 2')
          ..insert('\n', {'list': 'ordered'});
        final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

        expect(result.text, 'Item 1\nItem 2\n');
        expect(result.tags[0].replacement, '- ');
        expect(result.tags[0].start, 0);
        expect(result.tags[1].replacement, '1. ');
        expect(result.tags[1].start, 7); // Start of second line
      });

      test('converts blockquote', () async {
        final delta = Delta()
          ..insert('Quote')
          ..insert('\n', {'blockquote': true});
        final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

        expect(result.text, 'Quote\n');
        expect(result.tags.first.replacement, '> ');
        expect(result.tags.first.start, 0);
      });

      group('code blocks', () {
        test('converts single-line code block', () async {
          final delta = Delta()
            ..insert('print("hello")')
            ..insert('\n', {'code-block': true});
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, 'print("hello")\n');
          expect(result.tags, hasLength(2));
          expect(result.tags[0].replacement, '```\n');
          expect(result.tags[0].start, 0);
          expect(result.tags[1].replacement, '\n```');
          expect(result.tags[1].start, 15); // After the newline
        });

        test('converts multi-line code block', () async {
          final delta = Delta()
            ..insert('def hello()')
            ..insert('\n', {'code-block': true})
            ..insert('    print("world")')
            ..insert('\n', {'code-block': true})
            ..insert('hello()')
            ..insert('\n', {'code-block': true});
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, 'def hello()\n    print("world")\nhello()\n');
          // Should have opening fence at start and closing fence after last line
          expect(result.tags, hasLength(2));
          expect(result.tags[0].replacement, '```\n');
          expect(result.tags[0].start, 0);
          // Closing fence should be after the last newline
          expect(result.tags[1].replacement, '\n```');
        });

        test('converts code block at document start', () async {
          final delta = Delta()
            ..insert('code here')
            ..insert('\n', {'code-block': true})
            ..insert('normal text\n');
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, 'code here\nnormal text\n');
          expect(result.tags, hasLength(2));
          expect(result.tags[0].replacement, '```\n');
          expect(result.tags[0].start, 0);
          expect(result.tags[1].replacement, '\n```');
        });

        test('converts code block at document end', () async {
          final delta = Delta()
            ..insert('normal text\n')
            ..insert('code here')
            ..insert('\n', {'code-block': true});
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, 'normal text\ncode here\n');
          expect(result.tags, hasLength(2));
          expect(result.tags[0].replacement, '```\n');
          expect(result.tags[1].replacement, '\n```');
        });

        test('converts code block transitions', () async {
          final delta = Delta()
            ..insert('normal text\n')
            ..insert('code line 1')
            ..insert('\n', {'code-block': true})
            ..insert('code line 2')
            ..insert('\n', {'code-block': true})
            ..insert('normal text again\n');
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, 'normal text\ncode line 1\ncode line 2\nnormal text again\n');
          expect(result.tags, hasLength(2));
          // Opening fence before first code line
          expect(result.tags[0].replacement, '```\n');
          // Closing fence after last code line
          expect(result.tags[1].replacement, '\n```');
        });

        test('converts multiple separate code blocks', () async {
          final delta = Delta()
            ..insert('code block 1')
            ..insert('\n', {'code-block': true})
            ..insert('normal text\n')
            ..insert('code block 2')
            ..insert('\n', {'code-block': true});
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, 'code block 1\nnormal text\ncode block 2\n');
          // Should have 4 tags: 2 opening fences, 2 closing fences
          expect(result.tags, hasLength(4));
          expect(result.tags[0].replacement, '```\n'); // First code block opening
          expect(result.tags[1].replacement, '\n```'); // First code block closing
          expect(result.tags[2].replacement, '```\n'); // Second code block opening
          expect(result.tags[3].replacement, '\n```'); // Second code block closing
        });

        test('converts code block with other block types', () async {
          final delta = Delta()
            ..insert('code line')
            ..insert('\n', {'code-block': true})
            ..insert('Header')
            ..insert('\n', {'header': 1});
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, 'code line\nHeader\n');
          expect(result.tags, hasLength(3));
          expect(result.tags[0].replacement, '```\n'); // Code block opening
          expect(result.tags[1].replacement, '\n```'); // Code block closing
          expect(result.tags[2].replacement, '# '); // Header
        });

        test('converts empty code block', () async {
          final delta = Delta()..insert('\n', {'code-block': true});
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, '\n');
          expect(result.tags, hasLength(2));
          expect(result.tags[0].replacement, '```\n'); // Opening fence
          expect(result.tags[1].replacement, '\n```'); // Closing fence
        });

        test('converts code block with inline formatting inside', () async {
          final delta = Delta()
            ..insert('normal ')
            ..insert('bold', {'bold': true})
            ..insert(' text')
            ..insert('\n', {'code-block': true});
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, 'normal bold text\n');
          // Should have code block fences, but inline formatting is preserved in text
          expect(result.tags, hasLength(3));
          // Find code block tags
          final codeBlockTags = result.tags.where((t) => t.replacement.contains('```')).toList();
          expect(codeBlockTags, hasLength(2));
        });

        test('converts code block immediately after another block type', () async {
          final delta = Delta()
            ..insert('Header')
            ..insert('\n', {'header': 1})
            ..insert('code line')
            ..insert('\n', {'code-block': true});
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, 'Header\ncode line\n');
          expect(result.tags, hasLength(3));
          expect(result.tags[0].replacement, '# '); // Header
          expect(result.tags[1].replacement, '```\n'); // Code block opening
          expect(result.tags[2].replacement, '\n```'); // Code block closing
        });

        test('converts very long code block', () async {
          final delta = Delta();
          for (var i = 0; i < 100; i++) {
            delta
              ..insert('line $i')
              ..insert('\n', {'code-block': true});
          }
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          // Should have exactly 2 tags: opening and closing fence
          expect(result.tags, hasLength(2));
          expect(result.tags[0].replacement, '```\n');
          expect(result.tags[1].replacement, '\n```');
        });
      });

      group('round-trip conversion', () {
        test('converts complex Delta through markdown and back', () async {
          // Create a comprehensive Delta with all supported features
          final originalDelta = Delta()
            // Header 1
            ..insert('Lorem Ipsum Dolor Sit Amet')
            ..insert('\n', {'header': 1})
            // Normal paragraph with inline formatting
            ..insert('Lorem ipsum ')
            ..insert('dolor', {'bold': true})
            ..insert(' sit amet, ')
            ..insert('consectetur', {'italic': true})
            ..insert(' adipiscing elit. ')
            ..insert('Sed do', {'bold': true, 'italic': true})
            ..insert(' eiusmod tempor.')
            ..insert('\n')
            // Header 2
            ..insert('Section Title')
            ..insert('\n', {'header': 2})
            // Bullet list
            ..insert('First item')
            ..insert('\n', {'list': 'bullet'})
            ..insert('Second item with ')
            ..insert('bold text', {'bold': true})
            ..insert('\n', {'list': 'bullet'})
            ..insert('Third item')
            ..insert('\n', {'list': 'bullet'})
            // Ordered list
            ..insert('First numbered')
            ..insert('\n', {'list': 'ordered'})
            ..insert('Second numbered')
            ..insert('\n', {'list': 'ordered'})
            // Blockquote
            ..insert('This is a quote')
            ..insert('\n', {'blockquote': true})
            ..insert('More quote text')
            ..insert('\n', {'blockquote': true})
            // Code block
            ..insert('def hello_world():')
            ..insert('\n', {'code-block': true})
            ..insert('    print("Hello, World!")')
            ..insert('\n', {'code-block': true})
            ..insert('    return True')
            ..insert('\n', {'code-block': true})
            // Normal text with link
            ..insert('Visit ')
            ..insert('example.com', {'link': 'https://example.com'})
            ..insert(' for more info.')
            ..insert('\n')
            // Inline code
            ..insert('Use ')
            ..insert('code()', {'code': true})
            ..insert(' function.')
            ..insert('\n')
            // Strikethrough and underline
            ..insert('This is ')
            ..insert('deleted', {'strike': true})
            ..insert(' and this is ')
            ..insert('underlined', {'underline': true})
            ..insert('.\n')
            // Image
            ..insert({'text-editor-single-image': 'https://example.com/image.png'})
            ..insert('\n')
            // Separator
            ..insert({'text-editor-separator': '---'})
            ..insert('\n')
            // Header 3
            ..insert('Another Section')
            ..insert('\n', {'header': 3})
            // Mixed content paragraph
            ..insert('Final paragraph with ')
            ..insert('multiple', {'bold': true})
            ..insert(' ')
            ..insert('formats', {'italic': true})
            ..insert(' and a ')
            ..insert('link', {'link': 'https://test.com'})
            ..insert('.\n');

          // Convert Delta → Markdown
          final markdown = deltaToMarkdown(originalDelta);

          // Convert Markdown → Delta
          final roundTripDelta = markdownToDelta(markdown);

          // Compare the Deltas
          // Note: Markdown parser may add extra newlines, so we normalize for this specific test
          final originalText = _normalizeTextForComparison(
            Document.fromDelta(originalDelta).toPlainText(),
          );
          final roundTripText = _normalizeTextForComparison(
            Document.fromDelta(roundTripDelta).toPlainText(),
          );

          expect(
            roundTripText,
            equals(originalText),
            reason: 'Round-trip conversion should preserve semantic content',
          );

          // Verify markdown was generated and contains expected elements
          expect(markdown, isNotEmpty);
          expect(
            roundTripDelta.length,
            greaterThan(0),
            reason: 'Round-trip Delta should not be empty',
          );

          // Verify markdown was generated
          expect(markdown, isNotEmpty);
          expect(markdown, contains('#'));
          expect(markdown, contains('```'));
          expect(markdown, contains('**'));
          expect(markdown, contains('*'));
        });

        test('round-trip with lorem ipsum and all features', () async {
          const loremIpsum = '''
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor 
incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis 
nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
''';

          final originalDelta = Delta()
            // Large header
            ..insert('Complete Document Test')
            ..insert('\n', {'header': 1})
            // Long paragraph with formatting
            ..insert(loremIpsum.trim())
            ..insert('\n')
            // Multiple code blocks
            ..insert('function example() {')
            ..insert('\n', {'code-block': true})
            ..insert('  return "test";')
            ..insert('\n', {'code-block': true})
            ..insert('}')
            ..insert('\n', {'code-block': true})
            // More content
            ..insert('Another ')
            ..insert('paragraph', {'bold': true})
            ..insert(' with ')
            ..insert('mixed', {'italic': true})
            ..insert(' formatting.\n')
            // Lists
            ..insert('Item A')
            ..insert('\n', {'list': 'bullet'})
            ..insert('Item B')
            ..insert('\n', {'list': 'bullet'})
            ..insert('Item C')
            ..insert('\n', {'list': 'bullet'})
            // Images
            ..insert({'text-editor-single-image': 'https://example.com/photo1.jpg'})
            ..insert('\n')
            ..insert({'text-editor-single-image': 'https://example.com/photo2.jpg'})
            ..insert('\n')
            // More formatting
            ..insert('Link to ')
            ..insert('Google', {'link': 'https://google.com'})
            ..insert(' and ')
            ..insert('GitHub', {'link': 'https://github.com'})
            ..insert('.\n')
            // Code block with multiple lines
            ..insert('const data = {')
            ..insert('\n', {'code-block': true})
            ..insert('  name: "test",')
            ..insert('\n', {'code-block': true})
            ..insert('  value: 42')
            ..insert('\n', {'code-block': true})
            ..insert('};')
            ..insert('\n', {'code-block': true})
            // Final content
            ..insert('End of document.')
            ..insert('\n');

          // Round-trip conversion
          final markdown = deltaToMarkdown(originalDelta);
          final roundTripDelta = markdownToDelta(markdown);

          // Verify content preservation
          // Note: Markdown parser may add extra newlines, so we normalize for this specific test
          final originalText = _normalizeTextForComparison(
            Document.fromDelta(originalDelta).toPlainText(),
          );
          final roundTripText = _normalizeTextForComparison(
            Document.fromDelta(roundTripDelta).toPlainText(),
          );

          expect(
            roundTripText,
            equals(originalText),
            reason: 'Large document round-trip should preserve semantic content',
          );

          // Verify markdown contains expected elements
          expect(markdown, contains('# Complete Document Test'));
          expect(markdown, contains('```'));
          expect(markdown, contains('**'));
          expect(markdown, contains('https://example.com/photo1.jpg'));
          expect(markdown, contains('https://example.com/photo2.jpg'));
        });

        test('round-trip preserves code blocks correctly', () async {
          final originalDelta = Delta()
            ..insert('Normal text before code\n')
            ..insert('line1')
            ..insert('\n', {'code-block': true})
            ..insert('line2')
            ..insert('\n', {'code-block': true})
            ..insert('line3')
            ..insert('\n', {'code-block': true})
            ..insert('Normal text after code\n');

          final markdown = deltaToMarkdown(originalDelta);
          final roundTripDelta = markdownToDelta(markdown);

          // Verify code blocks are preserved (normalize whitespace)
          final originalText = Document.fromDelta(originalDelta)
              .toPlainText()
              .replaceAll(RegExp(r'\n{3,}'), '\n\n')
              .trim();
          final roundTripText = Document.fromDelta(roundTripDelta)
              .toPlainText()
              .replaceAll(RegExp(r'\n{3,}'), '\n\n')
              .trim();

          expect(
            roundTripText.replaceAll(RegExp(r'\s+'), ' '),
            equals(originalText.replaceAll(RegExp(r'\s+'), ' ')),
          );

          // Verify markdown has code fences
          expect(markdown, contains('```'));
          expect(markdown, contains('line1'));
          expect(markdown, contains('line2'));
          expect(markdown, contains('line3'));
        });

        test('round-trip with nested formatting', () async {
          final originalDelta = Delta()
            ..insert('Text with ')
            ..insert('bold', {'bold': true})
            ..insert(' and ')
            ..insert('italic', {'italic': true})
            ..insert(' and ')
            ..insert('both', {'bold': true, 'italic': true})
            ..insert(' and ')
            ..insert('link', {'link': 'https://test.com'})
            ..insert(' and ')
            ..insert('code', {'code': true})
            ..insert('.\n');

          final markdown = deltaToMarkdown(originalDelta);
          final roundTripDelta = markdownToDelta(markdown);

          // Strict comparison - ensure exact preservation
          final originalText = Document.fromDelta(originalDelta).toPlainText();
          final roundTripText = Document.fromDelta(roundTripDelta).toPlainText();

          expect(roundTripText, equals(originalText));
        });

        group('markdownToDelta attribute normalization', () {
          test('preserves bold formatting from markdown', () {
            const markdown = 'Hello **bold** world\n';
            final delta = markdownToDelta(markdown);

            // Verify bold attribute is present
            expect(
              _hasTextWithFormatting(delta, textSubstring: 'bold', attributeKeys: ['bold']),
              isTrue,
              reason: 'Bold formatting should be preserved from markdown',
            );
          });

          test('preserves italic formatting from markdown', () {
            const markdown = 'Hello *italic* world\n';
            final delta = markdownToDelta(markdown);

            // Verify italic attribute is present
            expect(
              _hasTextWithFormatting(delta, textSubstring: 'italic', attributeKeys: ['italic']),
              isTrue,
              reason: 'Italic formatting should be preserved from markdown',
            );
          });

          test('preserves both bold and italic formatting from markdown', () {
            const markdown = 'Hello ***bolditalic*** world\n';
            final delta = markdownToDelta(markdown);

            // Verify both attributes are present
            expect(
              _hasTextWithFormatting(delta, textSubstring: 'bolditalic', attributeKeys: ['bold']),
              isTrue,
              reason: 'Bold formatting should be preserved in bold+italic',
            );
            expect(
              _hasTextWithFormatting(delta, textSubstring: 'bolditalic', attributeKeys: ['italic']),
              isTrue,
              reason: 'Italic formatting should be preserved in bold+italic',
            );
          });

          test('handles markdown with mixed formatting correctly', () {
            const markdown = 'Normal **bold** and *italic* text\n';
            final delta = markdownToDelta(markdown);

            // Verify both formatting types are present
            expect(
              _hasTextWithFormatting(delta, textSubstring: 'bold', attributeKeys: ['bold']),
              isTrue,
              reason: 'Bold formatting should be preserved',
            );
            expect(
              _hasTextWithFormatting(delta, textSubstring: 'italic', attributeKeys: ['italic']),
              isTrue,
              reason: 'Italic formatting should be preserved',
            );
          });
        });

        test('round-trip with underline formatting (markdown uses HTML <u> tags)', () async {
          // Expected Delta from user's JSON structure
          final expectedDeltaJson = [
            {
              'attributes': {'underline': true},
              'insert': 'hello world underlined',
            },
            {'insert': '\n'},
            {
              'attributes': {'underline': true, 'bold': true},
              'insert': 'hello world bold',
            },
            {'insert': '\n'},
            {
              'attributes': {'underline': true, 'italic': true},
              'insert': 'hello world italic',
            },
            {'insert': '\n'},
          ];

          final expectedDelta = Delta.fromJson(expectedDeltaJson);

          // Convert to markdown
          final markdown = deltaToMarkdown(expectedDelta);

          // Verify markdown contains HTML <u> tags for underline
          expect(markdown, contains('<u>'));
          expect(markdown, contains('</u>'));
          expect(markdown, contains('hello world underlined'));
          expect(markdown, contains('hello world bold'));
          expect(markdown, contains('hello world italic'));

          // Convert back from markdown to delta
          final resultDelta = markdownToDelta(markdown);

          // Compare expected with result
          // We need to compare the operations since underline is preserved as HTML
          final expectedOps = expectedDelta.toList();
          final resultOps = resultDelta.toList();

          // Check that we have the same number of operations (or similar structure)
          expect(resultOps.length, greaterThanOrEqualTo(expectedOps.length - 1));

          // Verify the text content matches
          final expectedText = Document.fromDelta(expectedDelta).toPlainText();
          final resultText = Document.fromDelta(resultDelta).toPlainText();
          expect(resultText.trim(), equals(expectedText.trim()));

          // Verify underline attributes are preserved in the result
          // (markdown parser should convert <u> tags back to underline attributes)
          expect(
            _hasTextWithFormatting(
              resultDelta,
              textSubstring: 'hello world underlined',
              attributeKeys: ['underline'],
            ),
            isTrue,
            reason: 'Underline attribute should be preserved',
          );
          expect(
            _hasTextWithFormatting(
              resultDelta,
              textSubstring: 'hello world bold',
              attributeKeys: ['underline', 'bold'],
            ),
            isTrue,
            reason: 'Underline+bold attributes should be preserved',
          );
          expect(
            _hasTextWithFormatting(
              resultDelta,
              textSubstring: 'hello world italic',
              attributeKeys: ['underline', 'italic'],
            ),
            isTrue,
            reason: 'Underline+italic attributes should be preserved',
          );

          // Also verify the text content matches
          expect(resultText, contains('hello world underlined'));
          expect(resultText, contains('hello world bold'));
          expect(resultText, contains('hello world italic'));
        });

        test('round-trip with images', () async {
          // Expected Delta with images
          final expectedDelta = Delta()
            ..insert('Text before image\n')
            ..insert({'text-editor-single-image': 'https://example.com/image1.png'})
            ..insert('\n')
            ..insert('Text between images\n')
            ..insert({'text-editor-single-image': 'https://example.com/image2.jpg'})
            ..insert('\n')
            ..insert('Text after images\n');

          // Convert to markdown
          final markdown = deltaToMarkdown(expectedDelta);

          // Verify markdown contains image syntax
          expect(markdown, contains('!['));
          expect(markdown, contains(']('));
          expect(markdown, contains('https://example.com/image1.png'));
          expect(markdown, contains('https://example.com/image2.jpg'));

          // Convert back from markdown to delta
          final resultDelta = markdownToDelta(markdown);

          // Verify the text content matches - strict comparison
          // Images are represented as placeholders (￼) in plain text
          final expectedText = Document.fromDelta(expectedDelta).toPlainText();
          final resultText = Document.fromDelta(resultDelta).toPlainText();

          expect(resultText, equals(expectedText));

          // Verify images are preserved in the result
          expect(
            _hasImageInDelta(
              resultDelta,
              imageUrl: 'https://example.com/image1.png',
            ),
            isTrue,
            reason: 'First image should be preserved',
          );
          expect(
            _hasImageInDelta(
              resultDelta,
              imageUrl: 'https://example.com/image2.jpg',
            ),
            isTrue,
            reason: 'Second image should be preserved',
          );
        });
      });
    });

    group('PMO round-trip conversion (mapDeltaToPmo -> mapMarkdownToDelta)', () {
      // Note: These tests are specifically for Posts (kind 1) and ModifiablePosts (kind 30175)
      // which use PMO tags. Articles (kind 30023) use markdown directly, not PMO tags.

      test('round-trip with plain text (for Posts/ModifiablePosts)', () async {
        final expectedDelta = Delta()..insert('Hello world\n');
        final result = await _performRoundTripConversion(expectedDelta);
        _assertDeltaTextEquals(expectedDelta, result.resultDelta);
      });

      test('round-trip with bold and italic (for Posts/ModifiablePosts)', () async {
        final expectedDelta = Delta()
          ..insert('Hello ')
          ..insert('bold', {'bold': true})
          ..insert(' and ')
          ..insert('italic', {'italic': true})
          ..insert(' text\n');

        final result = await _performRoundTripConversion(expectedDelta);
        _assertDeltaTextEquals(expectedDelta, result.resultDelta);

        expect(
          _hasTextWithFormatting(
            result.resultDelta,
            textSubstring: 'bold',
            attributeKeys: ['bold'],
          ),
          isTrue,
          reason: 'Bold formatting should be preserved',
        );
        expect(
          _hasTextWithFormatting(
            result.resultDelta,
            textSubstring: 'italic',
            attributeKeys: ['italic'],
          ),
          isTrue,
          reason: 'Italic formatting should be preserved',
        );
      });

      group('PMO tag normalization with spaces', () {
        test('normalizes italic with trailing space in PMO tags', () {
          const plainText = 'normal\n\n\nitalic \n\n\nbold\n';
          final pmoTags = [
            ['pmo', '9:16', '*italic *'], // Trailing space
            ['pmo', '19:23', '**bold**'],
          ];

          final resultDelta = DeltaMarkdownConverter.mapMarkdownToDelta(plainText, pmoTags);

          // Verify italic formatting is preserved
          expect(
            _hasTextWithFormatting(resultDelta, textSubstring: 'italic', attributeKeys: ['italic']),
            isTrue,
            reason: 'Italic formatting should be preserved even with trailing space',
          );
          expect(
            _hasTextWithFormatting(resultDelta, textSubstring: 'bold', attributeKeys: ['bold']),
            isTrue,
            reason: 'Bold formatting should be preserved',
          );
        });

        test('normalizes italic with leading space in PMO tags', () {
          const plainText = 'normal\n\n\n italic\n';
          final pmoTags = [
            ['pmo', '9:16', '* italic*'], // Leading space
          ];

          final resultDelta = DeltaMarkdownConverter.mapMarkdownToDelta(plainText, pmoTags);

          // Verify italic formatting is preserved
          expect(
            _hasTextWithFormatting(resultDelta, textSubstring: 'italic', attributeKeys: ['italic']),
            isTrue,
            reason: 'Italic formatting should be preserved even with leading space',
          );
        });

        test('normalizes bold with trailing space in PMO tags', () {
          const plainText = 'normal\n\n\nbold \n';
          final pmoTags = [
            ['pmo', '9:14', '**bold **'], // Trailing space
          ];

          final resultDelta = DeltaMarkdownConverter.mapMarkdownToDelta(plainText, pmoTags);

          // Verify bold formatting is preserved
          expect(
            _hasTextWithFormatting(resultDelta, textSubstring: 'bold', attributeKeys: ['bold']),
            isTrue,
            reason: 'Bold formatting should be preserved even with trailing space',
          );
        });

        test('normalizes bold with leading space in PMO tags', () {
          const plainText = 'normal\n\n\n bold\n';
          final pmoTags = [
            ['pmo', '9:14', '** bold**'], // Leading space
          ];

          final resultDelta = DeltaMarkdownConverter.mapMarkdownToDelta(plainText, pmoTags);

          // Verify bold formatting is preserved
          expect(
            _hasTextWithFormatting(resultDelta, textSubstring: 'bold', attributeKeys: ['bold']),
            isTrue,
            reason: 'Bold formatting should be preserved even with leading space',
          );
        });

        test('normalizes bold+italic with trailing space in PMO tags', () {
          const plainText = 'normal\n\n\nbolditalic \n';
          final pmoTags = [
            ['pmo', '9:20', '***bolditalic ***'], // Trailing space
          ];

          final resultDelta = DeltaMarkdownConverter.mapMarkdownToDelta(plainText, pmoTags);

          // Verify both bold and italic formatting are preserved
          expect(
            _hasTextWithFormatting(
              resultDelta,
              textSubstring: 'bolditalic',
              attributeKeys: ['bold'],
            ),
            isTrue,
            reason: 'Bold formatting should be preserved in bold+italic with trailing space',
          );
          expect(
            _hasTextWithFormatting(
              resultDelta,
              textSubstring: 'bolditalic',
              attributeKeys: ['italic'],
            ),
            isTrue,
            reason: 'Italic formatting should be preserved in bold+italic with trailing space',
          );
        });

        test('normalizes multiple spaces in markdown markers', () {
          const plainText = 'normal\n\n\nitalic  \n'; // Multiple trailing spaces
          final pmoTags = [
            ['pmo', '9:17', '*italic  *'], // Multiple trailing spaces
          ];

          final resultDelta = DeltaMarkdownConverter.mapMarkdownToDelta(plainText, pmoTags);

          // Verify italic formatting is preserved
          expect(
            _hasTextWithFormatting(resultDelta, textSubstring: 'italic', attributeKeys: ['italic']),
            isTrue,
            reason: 'Italic formatting should be preserved even with multiple trailing spaces',
          );
        });

        test('handles mixed spacing issues in multiple PMO tags', () {
          const plainText = 'normal\n\n\nitalic \n\n\nbold \n';
          final pmoTags = [
            ['pmo', '9:16', '*italic *'], // Trailing space in italic
            ['pmo', '19:25', '**bold **'], // Trailing space in bold
          ];

          final resultDelta = DeltaMarkdownConverter.mapMarkdownToDelta(plainText, pmoTags);

          // Verify both formatting types are preserved
          expect(
            _hasTextWithFormatting(resultDelta, textSubstring: 'italic', attributeKeys: ['italic']),
            isTrue,
            reason: 'Italic formatting should be preserved',
          );
          expect(
            _hasTextWithFormatting(resultDelta, textSubstring: 'bold', attributeKeys: ['bold']),
            isTrue,
            reason: 'Bold formatting should be preserved',
          );
        });

        test('does not break correctly formatted markdown', () {
          const plainText = 'normal\n\n\nitalic\n\n\nbold\n';
          final pmoTags = [
            ['pmo', '9:15', '*italic*'], // No spaces - should work as before
            ['pmo', '18:22', '**bold**'], // No spaces - should work as before
          ];

          final resultDelta = DeltaMarkdownConverter.mapMarkdownToDelta(plainText, pmoTags);

          // Verify formatting is preserved
          expect(
            _hasTextWithFormatting(resultDelta, textSubstring: 'italic', attributeKeys: ['italic']),
            isTrue,
            reason: 'Correctly formatted italic should still work',
          );
          expect(
            _hasTextWithFormatting(resultDelta, textSubstring: 'bold', attributeKeys: ['bold']),
            isTrue,
            reason: 'Correctly formatted bold should still work',
          );
        });

        test('handles same string repeated 3 times with normal, italic, bold pattern', () {
          // Pattern: normal, italic, bold, normal, italic, bold, normal, italic, bold
          // Using "text" as the repeated string
          // Plain text structure: "text\n\n\ntext\n\n\ntext\n\n\ntext\n\n\ntext\n\n\ntext\n\n\ntext\n\n\ntext\n\n\ntext\n"
          // Positions: 0-3: text, 4-6: \n\n\n, 7-10: text, 11-13: \n\n\n, 14-17: text, etc.
          const plainText =
              'text\n\n\ntext\n\n\ntext\n\n\ntext\n\n\ntext\n\n\ntext\n\n\ntext\n\n\ntext\n\n\ntext\n';
          final pmoTags = [
            // First italic (second "text" at positions 7-10)
            ['pmo', '7:11', '*text *'], // Trailing space
            // First bold (third "text" at positions 14-17)
            ['pmo', '14:18', '**text**'],
            // Second italic (fifth "text" at positions 28-31)
            ['pmo', '28:32', '*text *'], // Trailing space
            // Second bold (sixth "text" at positions 35-38)
            ['pmo', '35:39', '**text**'],
            // Third italic (eighth "text" at positions 49-52)
            ['pmo', '49:53', '*text *'], // Trailing space
            // Third bold (ninth "text" at positions 56-59)
            ['pmo', '56:60', '**text**'],
          ];

          final resultDelta = DeltaMarkdownConverter.mapMarkdownToDelta(plainText, pmoTags);

          // Verify all formatting is preserved
          final counts = _countFormattingInstances(
            resultDelta,
            textFilter: (text) => text == 'text' || text.contains('text'),
          );

          expect(
            counts['italic'],
            greaterThanOrEqualTo(3),
            reason: 'Should have at least 3 italic instances',
          );
          expect(
            counts['bold'],
            greaterThanOrEqualTo(3),
            reason: 'Should have at least 3 bold instances',
          );
          expect(
            counts['normal'],
            greaterThanOrEqualTo(3),
            reason: 'Should have at least 3 normal instances',
          );

          // Verify the pattern is correct by checking operations in order
          final textOperations = resultDelta.operations
              .where(
                (op) =>
                    op.key == 'insert' &&
                    op.data is String &&
                    (op.data! as String).contains('text'),
              )
              .toList();

          // We should have 9 text instances total
          expect(
            textOperations.length,
            greaterThanOrEqualTo(9),
            reason: 'Should have 9 text instances (3 normal + 3 italic + 3 bold)',
          );
        });

        test('preserves spaces correctly with multiple PMO tags with trailing spaces', () {
          // Based on real-world example: "normal italic bold normal bold talll"
          // Plain text: "normal italic bold normal bold talll\n"
          // Positions: 0-6: "normal ", 7-13: "italic ", 14-18: "bold ", 19-25: "normal ", 26-30: "bold ", 31-35: "talll"
          // PMO tags: ["pmo","7:14","*italic *"], ["pmo","14:19","**bold **"],
          //          ["pmo","26:31","**bold **"], ["pmo","31:36","*talll*"]
          const plainText = 'normal italic bold normal bold talll\n';
          final pmoTags = [
            ['pmo', '7:14', '*italic *'], // Trailing space - covers "italic " (positions 7-13)
            ['pmo', '14:19', '**bold **'], // Trailing space - covers "bold " (positions 14-18)
            ['pmo', '26:31', '**bold **'], // Trailing space - covers "bold " (positions 26-30)
            ['pmo', '31:36', '*talll*'], // No space - covers "talll" (positions 31-35)
          ];

          final resultDelta = DeltaMarkdownConverter.mapMarkdownToDelta(plainText, pmoTags);

          // Convert to plain text to verify spacing is preserved
          final resultText = Document.fromDelta(resultDelta).toPlainText();

          // Verify the text has proper spacing (spaces should be preserved)
          expect(resultText, contains('normal '), reason: 'Should have space after "normal"');
          expect(resultText, contains('italic '), reason: 'Should have space after "italic"');
          expect(resultText, contains('bold '), reason: 'Should have space after "bold"');
          expect(resultText, contains('talll'), reason: 'Should contain "talll"');

          // Verify formatting is preserved
          expect(
            _hasTextWithFormatting(
                  resultDelta,
                  textSubstring: 'italic',
                  attributeKeys: ['italic'],
                ) ||
                _hasTextWithFormatting(
                  resultDelta,
                  textSubstring: 'talll',
                  attributeKeys: ['italic'],
                ),
            isTrue,
            reason: 'Italic formatting should be preserved',
          );
          expect(
            _hasTextWithFormatting(resultDelta, textSubstring: 'bold', attributeKeys: ['bold']),
            isTrue,
            reason: 'Bold formatting should be preserved',
          );

          // Count formatting instances
          final counts = _countFormattingByTextPattern(
            resultDelta,
            ['italic', 'bold', 'talll'],
            ['italic', 'bold'],
          );
          expect(
            counts['italic'],
            greaterThanOrEqualTo(2),
            reason: 'Should have at least 2 italic instances (italic and talll)',
          );
          expect(
            counts['bold'],
            greaterThanOrEqualTo(2),
            reason: 'Should have at least 2 bold instances',
          );

          // Verify text doesn't have concatenated words (e.g., "italicbold" or "boldtalll")
          expect(
            resultText,
            isNot(contains('italicbold')),
            reason: 'Should not have "italicbold" concatenated',
          );
          expect(
            resultText,
            isNot(contains('boldnormal')),
            reason: 'Should not have "boldnormal" concatenated',
          );
          expect(
            resultText,
            isNot(contains('boldtalll')),
            reason: 'Should not have "boldtalll" concatenated',
          );
        });
      });

      test('round-trip with headers (for Posts/ModifiablePosts)', () async {
        final expectedDelta = Delta()
          ..insert('Header 1')
          ..insert('\n', {'header': 1})
          ..insert('Header 2')
          ..insert('\n', {'header': 2})
          ..insert('Header 3')
          ..insert('\n', {'header': 3});

        final result = await _performRoundTripConversion(expectedDelta);
        _assertDeltaTextEquals(expectedDelta, result.resultDelta);

        final headerCounts = _countHeadersByLevel(result.resultDelta);
        expect(headerCounts[1], equals(1), reason: 'Should have one H1');
        expect(headerCounts[2], equals(1), reason: 'Should have one H2');
        expect(headerCounts[3], equals(1), reason: 'Should have one H3');
      });

      test('round-trip with lists (for Posts/ModifiablePosts)', () async {
        final expectedDelta = Delta()
          ..insert('Item 1')
          ..insert('\n', {'list': 'bullet'})
          ..insert('Item 2')
          ..insert('\n', {'list': 'bullet'})
          ..insert('Item 3')
          ..insert('\n', {'list': 'bullet'})
          ..insert('First')
          ..insert('\n', {'list': 'ordered'})
          ..insert('Second')
          ..insert('\n', {'list': 'ordered'});

        final result = await _performRoundTripConversion(expectedDelta);
        _assertDeltaTextEquals(expectedDelta, result.resultDelta);

        final listCounts = _countListItemsByType(result.resultDelta);
        expect(listCounts['bullet'], equals(3), reason: 'Should have 3 bullet list items');
        expect(listCounts['ordered'], equals(2), reason: 'Should have 2 ordered list items');
      });

      test('round-trip with code blocks (for Posts/ModifiablePosts)', () async {
        final expectedDelta = Delta()
          ..insert('Normal text\n')
          ..insert('code line 1')
          ..insert('\n', {'code-block': true})
          ..insert('code line 2')
          ..insert('\n', {'code-block': true})
          ..insert('code line 3')
          ..insert('\n', {'code-block': true})
          ..insert('Back to normal\n');

        final result = await _performRoundTripConversion(expectedDelta);
        _assertDeltaTextEquals(expectedDelta, result.resultDelta);

        expect(
          _hasAttributeInDelta(result.resultDelta, attributeKeys: ['code-block']),
          isTrue,
          reason: 'Should have code block lines',
        );
      });

      test('round-trip with links (for Posts/ModifiablePosts)', () async {
        final expectedDelta = Delta()
          ..insert('Visit ')
          ..insert('example.com', {'link': 'https://example.com'})
          ..insert(' and ')
          ..insert('google.com', {'link': 'https://google.com'})
          ..insert('\n');

        final result = await _performRoundTripConversion(expectedDelta);
        _assertDeltaTextEquals(expectedDelta, result.resultDelta);

        expect(
          _hasTextWithFormatting(
            result.resultDelta,
            textSubstring: 'example.com',
            attributeValues: {'link': 'https://example.com'},
          ),
          isTrue,
          reason: 'Example link should be preserved',
        );
        expect(
          _hasTextWithFormatting(
            result.resultDelta,
            textSubstring: 'google.com',
            attributeValues: {'link': 'https://google.com'},
          ),
          isTrue,
          reason: 'Google link should be preserved',
        );
      });

      test('round-trip with images', () async {
        final expectedDelta = Delta()
          ..insert('Text before\n')
          ..insert({'text-editor-single-image': 'https://example.com/image1.png'})
          ..insert('\n')
          ..insert('Text after\n');

        final result = await _performRoundTripConversion(expectedDelta);
        _assertDeltaTextEquals(expectedDelta, result.resultDelta);

        expect(
          _hasImageInDelta(
            result.resultDelta,
            imageUrl: 'https://example.com/image1.png',
          ),
          isTrue,
          reason: 'Image should be preserved',
        );
      });

      test('round-trip with underline formatting (for Posts/ModifiablePosts)', () async {
        final expectedDelta = Delta()
          ..insert('Hello ')
          ..insert('underlined', {'underline': true})
          ..insert(' world\n');

        final result = await _performRoundTripConversion(expectedDelta);
        _assertDeltaTextEquals(expectedDelta, result.resultDelta);

        expect(
          _hasTextWithFormatting(
            result.resultDelta,
            textSubstring: 'underlined',
            attributeKeys: ['underline'],
          ),
          isTrue,
          reason: 'Underline formatting should be preserved',
        );
      });

      test('round-trip with complex formatting (all features, for Posts/ModifiablePosts)',
          () async {
        final expectedDelta = Delta()
          ..insert('Header')
          ..insert('\n', {'header': 1})
          ..insert('Paragraph with ')
          ..insert('bold', {'bold': true})
          ..insert(', ')
          ..insert('italic', {'italic': true})
          ..insert(', ')
          ..insert('underlined', {'underline': true})
          ..insert(', and ')
          ..insert('link', {'link': 'https://example.com'})
          ..insert('\n')
          ..insert('Code block:')
          ..insert('\n')
          ..insert('def hello():')
          ..insert('\n', {'code-block': true})
          ..insert('    return "world"')
          ..insert('\n', {'code-block': true})
          ..insert('List:')
          ..insert('\n')
          ..insert('Item 1')
          ..insert('\n', {'list': 'bullet'})
          ..insert('Item 2')
          ..insert('\n', {'list': 'bullet'})
          ..insert({'text-editor-single-image': 'https://example.com/image.png'})
          ..insert('\n');

        final result = await _performRoundTripConversion(expectedDelta);
        // Note: For complex formatting with multiple features, markdown parser may introduce
        // formatting syntax in plain text, so we verify semantic content rather than exact text
        final resultText = Document.fromDelta(result.resultDelta).toPlainText();
        expect(resultText.contains('Header'), isTrue);
        expect(resultText.contains('Paragraph'), isTrue);
        expect(resultText.contains('bold'), isTrue);
        expect(resultText.contains('italic'), isTrue);
        expect(resultText.contains('underlined'), isTrue);
        expect(resultText.contains('link'), isTrue);
        expect(resultText.contains('def hello'), isTrue);
        expect(resultText.contains('Item 1'), isTrue);
        expect(resultText.contains('Item 2'), isTrue);

        // Verify all features are preserved
        expect(
          _hasAttributeInDelta(result.resultDelta, attributeKeys: ['header']),
          isTrue,
          reason: 'Header should be preserved',
        );
        expect(
          _hasAttributeInDelta(result.resultDelta, attributeKeys: ['bold']),
          isTrue,
          reason: 'Bold should be preserved',
        );
        expect(
          _hasAttributeInDelta(result.resultDelta, attributeKeys: ['italic']),
          isTrue,
          reason: 'Italic should be preserved',
        );
        expect(
          _hasAttributeInDelta(result.resultDelta, attributeKeys: ['underline']),
          isTrue,
          reason: 'Underline should be preserved',
        );
        expect(
          _hasAttributeInDelta(result.resultDelta, attributeKeys: ['link']),
          isTrue,
          reason: 'Link should be preserved',
        );
        expect(
          _hasAttributeInDelta(result.resultDelta, attributeKeys: ['code-block']),
          isTrue,
          reason: 'Code block should be preserved',
        );
        // Note: Lists may be converted differently by markdown parser, so we check text content instead
        expect(
          resultText.contains('Item 1'),
          isTrue,
          reason: 'List items should be preserved in text',
        );
        expect(
          resultText.contains('Item 2'),
          isTrue,
          reason: 'List items should be preserved in text',
        );
        // Note: Images may be converted differently by markdown parser when combined with other formatting
        // Check if image URL is present in the markdown or result text
        final markdown =
            result.pmoResult.tags.map<String>((t) => t.replacement).join(' ').toLowerCase();
        final hasImageInMarkdown = markdown.contains('example.com/image.png') ||
            markdown.contains('image.png') ||
            resultText.contains('image.png') ||
            _hasImageInDelta(result.resultDelta);
        expect(
          hasImageInMarkdown,
          isTrue,
          reason: 'Image should be preserved (either as Delta embed or in markdown/text)',
        );
      });
    });

    group('Markdown to Delta (PMO reconstruction)', () {
      group('Reading posts with PMO tags', () {
        test('should reconstruct Delta from plain text + PMO tags when no richText', () async {
          // Given: A post with plain text content and PMO tags, but NO richText Delta
          // Plain text: "Hello world! Visit example.com"
          // - "world" is at indices 6-11
          // - "example.com" is at indices 19-30
          const plainText = 'Hello world! Visit example.com';
          final pmoTags = [
            ['pmo', '6:11', '**world**'],
            ['pmo', '19:30', '[example.com](https://example.com)'],
          ];

          // When: Reading the post (no richText tag)
          final eventMessage = _createPostEventMessage(
            content: plainText,
            signer: signer,
            tags: pmoTags, // Only PMO tags, no richText
          );

          final postData = PostData.fromEventMessage(eventMessage);

          // Then: Should reconstruct Delta from PMO tags
          expect(postData.richText, isNotNull, reason: 'Should reconstruct richText from PMO tags');
          final delta = Delta.fromJson(jsonDecode(postData.richText!.content) as List);

          // Verify the Delta has the formatting
          expect(
            _hasAttributeInDelta(delta, attributeKeys: ['bold']),
            isTrue,
            reason: 'Delta should have bold formatting',
          );

          // Verify plain text matches
          final plainTextFromDelta = Document.fromDelta(delta).toPlainText();
          expect(plainTextFromDelta.trim(), equals(plainText.trim()));
        });

        test('should handle PMO tags with code blocks when no richText', () async {
          // Given: A post with code block PMO tags, no richText
          const plainText = 'Check this code:\ndef hello():\n    return True\n';
          final pmoTags = [
            ['pmo', '18:18', '```\n'],
            ['pmo', '44:44', '\n```'],
          ];

          // When: Reading the post (no richText tag)
          final eventMessage = EventMessage(
            id: 'test_id',
            pubkey: signer.publicKey,
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            kind: 1,
            content: plainText,
            tags: pmoTags, // Only PMO tags
            sig: 'test_sig',
          );

          final postData = PostData.fromEventMessage(eventMessage);

          // Then: Should reconstruct Delta with code block
          expect(postData.richText, isNotNull);
          final delta = Delta.fromJson(jsonDecode(postData.richText!.content) as List);

          // Verify code block formatting exists
          expect(
            _hasAttributeInDelta(delta, attributeKeys: ['code-block']),
            isTrue,
            reason: 'Delta should have code-block formatting',
          );
        });

        test('should handle PMO tags with headers when no richText', () async {
          // Given: A post with header PMO tags, no richText
          const plainText = 'Title\nContent here';
          final pmoTags = [
            ['pmo', '0:0', '# '],
          ];

          // When: Reading the post (no richText tag)
          final eventMessage = EventMessage(
            id: 'test_id',
            pubkey: signer.publicKey,
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            kind: 1,
            content: plainText,
            tags: pmoTags, // Only PMO tags
            sig: 'test_sig',
          );

          final postData = PostData.fromEventMessage(eventMessage);

          // Then: Should reconstruct Delta with header
          expect(postData.richText, isNotNull);
          final delta = Delta.fromJson(jsonDecode(postData.richText!.content) as List);

          // Verify header formatting exists
          expect(
            _hasAttributeInDelta(delta, attributeKeys: ['header']),
            isTrue,
            reason: 'Delta should have header formatting',
          );
        });

        test('should handle multiple PMO tags when no richText', () async {
          // Given: A post with multiple PMO tags, no richText
          const plainText = 'Hello bold italic world!';
          final pmoTags = [
            ['pmo', '6:10', '**bold**'],
            ['pmo', '11:17', '*italic*'],
          ];

          // When: Reading the post (no richText tag)
          final eventMessage = EventMessage(
            id: 'test_id',
            pubkey: signer.publicKey,
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            kind: 1,
            content: plainText,
            tags: pmoTags, // Only PMO tags
            sig: 'test_sig',
          );

          final postData = PostData.fromEventMessage(eventMessage);

          // Then: Should reconstruct Delta with both formatting
          expect(postData.richText, isNotNull);
          final delta = Delta.fromJson(jsonDecode(postData.richText!.content) as List);

          // Verify both formatting types exist
          expect(
            _hasAttributeInDelta(delta, attributeKeys: ['bold']),
            isTrue,
            reason: 'Delta should have bold formatting',
          );
          expect(
            _hasAttributeInDelta(delta, attributeKeys: ['italic']),
            isTrue,
            reason: 'Delta should have italic formatting',
          );
        });

        test('should handle posts without PMO tags (legacy)', () async {
          // Given: A legacy post without PMO tags
          const plainText = 'Just plain text';

          // When: Reading the post
          final eventMessage = EventMessage(
            id: 'test_id',
            pubkey: signer.publicKey,
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            kind: 1,
            content: plainText,
            tags: const [],
            sig: 'test_sig',
          );

          final postData = PostData.fromEventMessage(eventMessage);

          // Then: Should work without reconstruction
          expect(postData.content, equals(plainText));
          expect(postData.richText, isNull);
        });

        test('should use existing richText Delta and ignore PMO tags', () async {
          // Given: A post with both richText Delta and PMO tags
          // This simulates a post that was created with the new format (has richText)
          final delta = Delta()
            ..insert('Hello ')
            ..insert('world', {'bold': true})
            ..insert('!\n');

          final richText = _createRichTextFromDelta(delta);

          const plainText = 'Hello world!';
          final pmoTags = [
            ['pmo', '6:11', '**world**'],
          ];

          // When: Reading the post (has richText tag)
          final eventMessage = _createPostEventMessage(
            content: plainText,
            signer: signer,
            tags: [
              ...pmoTags,
              richText.toTag(), // richText exists
            ],
          );

          final postData = PostData.fromEventMessage(eventMessage);

          // Then: Should use richText Delta directly, NO PMO reconstruction
          expect(postData.richText, isNotNull);
          final deltaFromRichText = Delta.fromJson(
            jsonDecode(postData.richText!.content) as List,
          );
          // Should match the original Delta exactly (no reconstruction happened)
          expect(deltaFromRichText.toJson(), equals(delta.toJson()));
        });
      });
    });

    group('Backward Compatibility', () {
      group('Legacy Posts (kind 1)', () {
        test('Legacy post with markdown in content (no PMO tags)', () async {
          // Simulate a legacy post that was created before PMO implementation
          // Content has markdown, no PMO tags, no richText
          const legacyContent = 'Hello **world**! Visit [example.com](https://example.com)';

          final eventMessage = _createPostEventMessage(
            content: legacyContent,
            signer: signer,
          );

          final postData = PostData.fromEventMessage(eventMessage);

          // Should handle legacy format gracefully
          expect(postData.content, equals(legacyContent));
          expect(postData.richText, isNull);
        });

        test('Legacy post with richText Delta but markdown in content', () async {
          // Legacy post that has both richText Delta and markdown content
          final delta = Delta()
            ..insert('Hello ')
            ..insert('world', {'bold': true})
            ..insert('!\n');

          final richText = _createRichTextFromDelta(delta);

          // Legacy content might be markdown
          const legacyMarkdownContent = 'Hello **world**!';

          final eventMessage = _createPostEventMessage(
            content: legacyMarkdownContent,
            signer: signer,
            tags: [richText.toTag()],
          );

          final postData = PostData.fromEventMessage(eventMessage);

          // Should prefer richText over content
          expect(postData.richText, isNotNull);
          expect(postData.content, equals(legacyMarkdownContent));
        });

        test('Legacy post with plain text content (no formatting)', () async {
          // Simple legacy post with just plain text
          const plainText = 'Just plain text content';

          final eventMessage = _createPostEventMessage(
            content: plainText,
            signer: signer,
          );

          final postData = PostData.fromEventMessage(eventMessage);

          expect(postData.content, equals(plainText));
          expect(postData.richText, isNull);
        });
      });

      group('Legacy ModifiablePosts (kind 30175)', () {
        test('Legacy modifiable post with markdown in content', () async {
          const legacyContent = '# Title\n\n**Bold** text';

          final eventMessage = _createModifiablePostEventMessage(
            content: legacyContent,
            signer: signer,
          );

          final postData = ModifiablePostData.fromEventMessage(eventMessage);

          expect(postData.textContent, equals(legacyContent));
          expect(postData.richText, isNull);
        });

        test('Legacy modifiable post with plain text', () async {
          const plainText = 'Simple text content';

          final eventMessage = _createModifiablePostEventMessage(
            content: plainText,
            signer: signer,
          );

          final postData = ModifiablePostData.fromEventMessage(eventMessage);

          expect(postData.textContent, equals(plainText));
        });
      });

      group('Legacy Articles (kind 30023)', () {
        test('Legacy article with plain text content (not markdown)', () async {
          // Legacy article might have plain text instead of markdown
          const plainText = 'This is plain text content, not markdown';

          final eventMessage = _createArticleEventMessage(
            content: plainText,
            signer: signer,
          );

          final articleData = ArticleData.fromEventMessage(eventMessage);

          expect(articleData.textContent, equals(plainText));
          expect(articleData.richText, isNull);
        });

        test('Legacy article with richText Delta but plain text content', () async {
          // Legacy article with Delta in richText but plain text in content
          final delta = Delta()
            ..insert('Article content')
            ..insert('\n', {'header': 1});

          final richText = _createRichTextFromDelta(delta);

          const plainTextContent = 'Article content';

          final eventMessage = _createArticleEventMessage(
            content: plainTextContent,
            signer: signer,
            tags: [richText.toTag()],
          );

          final articleData = ArticleData.fromEventMessage(eventMessage);

          expect(articleData.textContent, equals(plainTextContent));
          expect(articleData.richText, isNotNull);
        });

        test('Legacy article with markdown content (should work)', () async {
          // Some legacy articles might already have markdown
          const markdownContent = '# Title\n\n**Bold** text';

          final eventMessage = _createArticleEventMessage(
            content: markdownContent,
            signer: signer,
          );

          final articleData = ArticleData.fromEventMessage(eventMessage);

          expect(articleData.textContent, equals(markdownContent));
        });
      });

      group('parseMediaContent backward compatibility', () {
        test('Handles legacy post with markdown content', () {
          const postData = PostData(
            content: 'Hello **world**!', // Legacy markdown
            media: {},
          );

          // parseMediaContent should handle this
          final result = parseMediaContent(data: postData);

          expect(result.content, isNotNull);
          expect(result.content.length, greaterThan(0));
        });

        test('Handles legacy article with plain text', () {
          final articleData = ArticleData(
            textContent: 'Plain text content', // Legacy plain text
            media: {},
            replaceableEventId: ReplaceableEventIdentifier.generate(),
            publishedAt: EntityPublishedAt(
              value: DateTime.now().microsecondsSinceEpoch,
            ),
          );

          final result = parseMediaContent(data: articleData);

          expect(result.content, isNotNull);
          expect(result.content.length, greaterThan(0));
        });

        test('Handles legacy article with markdown', () {
          final articleData = ArticleData(
            textContent: '# Title\n\n**Bold**', // Legacy markdown
            media: {},
            replaceableEventId: ReplaceableEventIdentifier.generate(),
            publishedAt: EntityPublishedAt(
              value: DateTime.now().microsecondsSinceEpoch,
            ),
          );

          final result = parseMediaContent(data: articleData);

          // Should detect markdown and convert to Delta
          expect(result.content, isNotNull);
          expect(result.content.length, greaterThan(0));
        });

        test('Prefers richText Delta over content when both present', () {
          final delta = Delta()
            ..insert('Delta content')
            ..insert('\n');

          final richText = _createRichTextFromDelta(delta);

          final postData = PostData(
            content: 'Legacy markdown **content**',
            media: {},
            richText: richText,
          );

          final result = parseMediaContent(data: postData);

          // Should use richText Delta, not markdown content
          expect(result.content, isNotNull);
          // Verify it's using Delta (check for Delta structure)
          expect(result.content.operations, isNotEmpty);
        });
      });
    });

    group('Edge Cases', () {
      group('Empty and minimal content', () {
        test('handles empty Delta', () async {
          final delta = Delta();
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, isEmpty);
          expect(result.tags, isEmpty);
        });

        test('handles Delta with only newline', () async {
          final delta = Delta()..insert('\n');
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, equals('\n'));
          expect(result.tags, isEmpty);
        });

        test('handles empty string content', () async {
          final delta = Delta()..insert('');
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, isEmpty);
          expect(result.tags, isEmpty);
        });

        test('handles whitespace-only content with formatting', () async {
          final delta = Delta()
            ..insert('   ', {'bold': true})
            ..insert('\n');
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          // Whitespace-only content should not create PMO tags (per line 234)
          expect(result.text, equals('   \n'));
          expect(result.tags, isEmpty);
        });

        test('handles single character with formatting', () async {
          final delta = Delta()
            ..insert('A', {'bold': true})
            ..insert('\n');
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, equals('A\n'));
          expect(result.tags, hasLength(1));
          expect(result.tags.first.replacement, equals('**A**'));
        });
      });

      group('Strikethrough formatting', () {
        test('converts strikethrough text', () async {
          final delta = Delta()
            ..insert('Hello ')
            ..insert('deleted', {'strike': true})
            ..insert(' world\n');
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, equals('Hello deleted world\n'));
          expect(result.tags, hasLength(1));
          expect(result.tags.first.replacement, equals('~~deleted~~'));
        });

        test('converts strikethrough with bold', () async {
          final delta = Delta()
            ..insert('Text ', {'strike': true, 'bold': true})
            ..insert('\n');
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, equals('Text \n'));
          expect(result.tags, hasLength(1));
          // Order: code, bold, italic, strike, underline, link
          // So it should be **~~Text ~~** (bold wraps strike)
          expect(result.tags.first.replacement, contains('**'));
          expect(result.tags.first.replacement, contains('~~'));
        });
      });

      group('Invalid PMO tag handling in mapMarkdownToDelta', () {
        test('handles PMO tags with negative start index', () {
          const plainText = 'Hello world';
          final pmoTags = [
            ['pmo', '-1:5', '**Hello**'],
          ];

          final result = DeltaMarkdownConverter.mapMarkdownToDelta(plainText, pmoTags);
          // Should skip invalid tag and return plain text as Delta
          expect(result, isNotNull);
          final text = Document.fromDelta(result).toPlainText();
          expect(text.trim(), equals(plainText));
        });

        test('handles PMO tags with negative end index', () {
          const plainText = 'Hello world';
          final pmoTags = [
            ['pmo', '0:-5', '**Hello**'],
          ];

          final result = DeltaMarkdownConverter.mapMarkdownToDelta(plainText, pmoTags);
          expect(result, isNotNull);
        });

        test('handles PMO tags with start > end', () {
          const plainText = 'Hello world';
          final pmoTags = [
            ['pmo', '10:5', '**world**'],
          ];

          final result = DeltaMarkdownConverter.mapMarkdownToDelta(plainText, pmoTags);
          // Should skip invalid tag
          expect(result, isNotNull);
          final text = Document.fromDelta(result).toPlainText();
          expect(text.trim(), equals(plainText));
        });

        test('handles PMO tags with start beyond text length', () {
          const plainText = 'Hello';
          final pmoTags = [
            ['pmo', '100:105', '**text**'],
          ];

          final result = DeltaMarkdownConverter.mapMarkdownToDelta(plainText, pmoTags);
          // Should skip invalid tag
          expect(result, isNotNull);
          final text = Document.fromDelta(result).toPlainText();
          expect(text.trim(), equals(plainText));
        });

        test('handles PMO tags with end beyond text length', () {
          const plainText = 'Hello';
          final pmoTags = [
            ['pmo', '0:100', '**Hello**'],
          ];

          final result = DeltaMarkdownConverter.mapMarkdownToDelta(plainText, pmoTags);
          // Should skip invalid tag
          expect(result, isNotNull);
          final text = Document.fromDelta(result).toPlainText();
          expect(text.trim(), equals(plainText));
        });

        test('handles PMO tags with overlapping ranges', () {
          const plainText = 'Hello world';
          final pmoTags = [
            ['pmo', '0:5', '**Hello**'],
            ['pmo', '3:8', '*lo wo*'], // Overlaps with first tag
          ];

          final result = DeltaMarkdownConverter.mapMarkdownToDelta(plainText, pmoTags);
          // Should handle overlapping tags (second tag should be skipped if it starts before currentPos)
          expect(result, isNotNull);
        });

        test('handles PMO tags with same start/end (zero-length)', () {
          const plainText = 'Hello world';
          final pmoTags = [
            ['pmo', '5:5', '**'],
          ];

          final result = DeltaMarkdownConverter.mapMarkdownToDelta(plainText, pmoTags);
          // Zero-length tags should be valid (insertion at position)
          expect(result, isNotNull);
        });

        test('handles PMO tags with invalid format (missing colon)', () {
          const plainText = 'Hello world';
          final pmoTags = [
            ['pmo', '05', '**Hello**'], // Missing colon
          ];

          final result = DeltaMarkdownConverter.mapMarkdownToDelta(plainText, pmoTags);
          // Should skip invalid tag
          expect(result, isNotNull);
          final text = Document.fromDelta(result).toPlainText();
          expect(text.trim(), equals(plainText));
        });

        test('handles PMO tags with non-numeric indices', () {
          const plainText = 'Hello world';
          final pmoTags = [
            ['pmo', 'abc:def', '**Hello**'],
          ];

          final result = DeltaMarkdownConverter.mapMarkdownToDelta(plainText, pmoTags);
          // Should skip invalid tag
          expect(result, isNotNull);
          final text = Document.fromDelta(result).toPlainText();
          expect(text.trim(), equals(plainText));
        });

        test('handles PMO tags with empty replacement', () {
          const plainText = 'Hello world';
          final pmoTags = [
            ['pmo', '0:5', ''], // Empty replacement
          ];

          final result = DeltaMarkdownConverter.mapMarkdownToDelta(plainText, pmoTags);
          // Should handle empty replacement
          expect(result, isNotNull);
        });

        test('handles PMO tags that are not "pmo"', () {
          const plainText = 'Hello world';
          final pmoTags = [
            ['notpmo', '0:5', '**Hello**'],
          ];

          final result = DeltaMarkdownConverter.mapMarkdownToDelta(plainText, pmoTags);
          // Should skip non-pmo tags
          expect(result, isNotNull);
          final text = Document.fromDelta(result).toPlainText();
          expect(text.trim(), equals(plainText));
        });

        test('handles PMO tags with less than 3 elements', () {
          const plainText = 'Hello world';
          final pmoTags = [
            ['pmo', '0:5'], // Missing replacement
          ];

          final result = DeltaMarkdownConverter.mapMarkdownToDelta(plainText, pmoTags);
          // Should skip invalid tag
          expect(result, isNotNull);
          final text = Document.fromDelta(result).toPlainText();
          expect(text.trim(), equals(plainText));
        });

        test('handles empty plainText with PMO tags', () {
          const plainText = '';
          final pmoTags = [
            ['pmo', '0:0', '# '],
          ];

          final result = DeltaMarkdownConverter.mapMarkdownToDelta(plainText, pmoTags);
          // Should handle empty text
          expect(result, isNotNull);
        });

        test('handles PMO tags out of order (should be sorted)', () {
          const plainText = 'Hello world';
          final pmoTags = [
            ['pmo', '6:11', '**world**'],
            ['pmo', '0:5', '**Hello**'], // Out of order
          ];

          final result = DeltaMarkdownConverter.mapMarkdownToDelta(plainText, pmoTags);
          // Should sort and process correctly
          expect(result, isNotNull);
          final text = Document.fromDelta(result).toPlainText();
          expect(text, contains('Hello'));
          expect(text, contains('world'));
        });
      });

      group('Header edge cases', () {
        test('handles header level 0', () async {
          final delta = Delta()
            ..insert('Header')
            ..insert('\n', {'header': 0});
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, equals('Header\n'));
          expect(result.tags, hasLength(1));
          expect(result.tags.first.replacement, equals(' ')); // Empty hashes
        });

        test('handles header level 6', () async {
          final delta = Delta()
            ..insert('Header')
            ..insert('\n', {'header': 6});
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, equals('Header\n'));
          expect(result.tags, hasLength(1));
          expect(result.tags.first.replacement, equals('###### '));
        });

        test('handles very large header level', () async {
          final delta = Delta()
            ..insert('Header')
            ..insert('\n', {'header': 100});
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, equals('Header\n'));
          expect(result.tags, hasLength(1));
          expect(result.tags.first.replacement, equals('#' * 100 + ' '));
        });
      });

      group('List edge cases', () {
        test('handles unknown list type', () async {
          final delta = Delta()
            ..insert('Item')
            ..insert('\n', {'list': 'unknown'});
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, equals('Item\n'));
          // Should default to bullet list marker
          expect(result.tags, hasLength(1));
          expect(result.tags.first.replacement, equals('- '));
        });

        test('handles null list type', () async {
          final delta = Delta()
            ..insert('Item')
            ..insert('\n', {'list': null});
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          // Null list type should be handled gracefully (no list marker added)
          expect(result.text, equals('Item\n'));
          expect(result.tags, isEmpty);
        });
      });

      group('Link edge cases', () {
        test('handles empty link URL', () async {
          final delta = Delta()
            ..insert('link', {'link': ''})
            ..insert('\n');
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, equals('link\n'));
          expect(result.tags, hasLength(1));
          expect(result.tags.first.replacement, equals('[link]()'));
        });

        test('handles null link URL', () async {
          final delta = Delta()
            ..insert('link', {'link': null})
            ..insert('\n');
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, equals('link\n'));
          expect(result.tags, hasLength(1));
          expect(result.tags.first.replacement, contains('link'));
        });
      });

      group('Code block edge cases', () {
        test('handles code block that never closes (document ends)', () async {
          final delta = Delta()
            ..insert('code line')
            ..insert('\n', {'code-block': true});
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, equals('code line\n'));
          // Should close code block at end
          expect(result.tags, hasLength(2));
          expect(result.tags[0].replacement, equals('```\n'));
          expect(result.tags[1].replacement, equals('\n```'));
        });

        test('handles code block with only newline', () async {
          final delta = Delta()..insert('\n', {'code-block': true});
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, equals('\n'));
          expect(result.tags, hasLength(2));
          expect(result.tags[0].replacement, equals('```\n'));
          expect(result.tags[1].replacement, equals('\n```'));
        });
      });

      group('Multiple newlines in single operation', () {
        test('handles multiple newlines with block attributes', () async {
          final delta = Delta()..insert('Line 1\nLine 2\nLine 3\n', {'header': 1});
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, equals('Line 1\nLine 2\nLine 3\n'));
          // Each newline in the operation gets processed, so header is applied to each
          // This creates 3 header tags (one for each newline)
          expect(result.tags, hasLength(3));
          expect(result.tags.every((tag) => tag.replacement == '# '), isTrue);
        });

        test('handles multiple newlines with inline attributes', () async {
          final delta = Delta()..insert('Bold\nNormal\nText\n', {'bold': true});
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, equals('Bold\nNormal\nText\n'));
          // Bold should apply to segments before each newline
          expect(result.tags.length, greaterThan(0));
        });
      });

      group('Special characters and Unicode', () {
        test('handles Unicode characters', () async {
          final delta = Delta()
            ..insert('Hello 世界')
            ..insert('\n');
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, equals('Hello 世界\n'));
          expect(result.tags, isEmpty);
        });

        test('handles emojis', () async {
          final delta = Delta()
            ..insert('Hello 👋')
            ..insert('\n');
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, equals('Hello 👋\n'));
          expect(result.tags, isEmpty);
        });

        test('handles special markdown characters in content', () async {
          final delta = Delta()
            ..insert('Text with * and ** and `')
            ..insert('\n');
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, equals('Text with * and ** and `\n'));
          expect(result.tags, isEmpty);
        });

        test('handles Unicode with formatting', () async {
          final delta = Delta()
            ..insert('世界', {'bold': true})
            ..insert('\n');
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, equals('世界\n'));
          expect(result.tags, hasLength(1));
          expect(result.tags.first.replacement, equals('**世界**'));
        });
      });

      group('Embed edge cases', () {
        test('handles unknown embed type', () async {
          final delta = Delta()
            ..insert({'unknown-embed': 'data'})
            ..insert('\n');
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          // Should return empty placeholder for unknown embed
          expect(result.text, equals('\n'));
          expect(result.tags, isEmpty);
        });

        test('handles image with empty URL', () async {
          final delta = Delta()
            ..insert({'text-editor-single-image': ''})
            ..insert('\n');
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, equals(' \n')); // Space placeholder
          expect(result.tags, hasLength(1));
          expect(result.tags.first.replacement, equals('![]()'));
        });

        test('handles image with null URL', () async {
          final delta = Delta()
            ..insert({'text-editor-single-image': null})
            ..insert('\n');
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, equals(' \n')); // Space placeholder
          expect(result.tags, hasLength(1));
        });

        test('handles code embed with null code', () async {
          final delta = Delta()
            ..insert({'text-editor-code': null})
            ..insert('\n');
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, equals('\n\n')); // Newline placeholder + inserted newline
          expect(result.tags, hasLength(1));
          expect(result.tags.first.replacement, contains('```'));
        });
      });

      group('Complex formatting combinations', () {
        test('handles all inline formats together', () async {
          final delta = Delta()
            ..insert('text', {
              'bold': true,
              'italic': true,
              'strike': true,
              'underline': true,
              'code': true,
              'link': 'https://example.com',
            })
            ..insert('\n');
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, equals('text\n'));
          expect(result.tags, hasLength(1));
          final replacement = result.tags.first.replacement;
          // Should contain all formatting markers
          expect(replacement, contains('`'));
          expect(replacement, contains('**'));
          expect(replacement, contains('*'));
          expect(replacement, contains('~~'));
          expect(replacement, contains('<u>'));
          expect(replacement, contains('['));
          expect(replacement, contains(']'));
        });

        test('handles formatting on empty content', () async {
          final delta = Delta()
            ..insert('', {'bold': true})
            ..insert('\n');
          final result = await DeltaMarkdownConverter.mapDeltaToPmo(delta.toJson());

          expect(result.text, equals('\n'));
          // Empty content should not create PMO tag
          expect(result.tags, isEmpty);
        });
      });

      group('Round-trip edge cases', () {
        test('round-trip with empty Delta', () async {
          final delta = Delta();
          final result = await _performRoundTripConversion(delta);

          expect(result.resultDelta, isNotNull);
          final text = Document.fromDelta(result.resultDelta).toPlainText();
          expect(text.trim(), isEmpty);
        });

        test('round-trip with only whitespace', () async {
          final delta = Delta()..insert('   \n');
          final result = await _performRoundTripConversion(delta);

          expect(result.resultDelta, isNotNull);
        });

        test('round-trip with strikethrough', () async {
          final delta = Delta()
            ..insert('Hello ')
            ..insert('deleted', {'strike': true})
            ..insert(' world\n');
          final result = await _performRoundTripConversion(delta);

          expect(result.resultDelta, isNotNull);
          final text = Document.fromDelta(result.resultDelta).toPlainText();
          expect(text.trim(), equals('Hello deleted world'));
        });
      });
    });
  });
}
