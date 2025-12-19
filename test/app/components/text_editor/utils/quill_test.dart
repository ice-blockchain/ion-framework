// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/components/text_editor/utils/quill_text_utils.dart';

import '../../../../test_utils.dart';

void main() {
  group('trimDeltaJson', () {
    // Helper to encode ops into a delta JSON string.
    // String deltaJson(List<Map<String, dynamic>> ops) => jsonEncode(ops);
    String deltaJson(List<Map<String, dynamic>> ops) => jsonEncode(ops);

    parameterizedGroup('returns null when content is empty or just whitespace', [
      (input: null, desc: 'null'),
      (input: '', desc: 'empty string'),
      // ignore: use_raw_strings
      (input: '[{"insert":"\\n\\n\\n"}]', desc: 'only newlines'),
      // ignore: use_raw_strings
      (input: '[{"insert":"   \\n\\n"}]', desc: 'spaces + newlines'),
    ], (t) {
      test('case: ${t.desc}', () {
        expect(QuillTextUtils.trimDeltaJson(t.input), isNull);
      });
    });

    test('returns input unchanged when JSON cannot be parsed', () {
      const bad = 'not-json';
      expect(QuillTextUtils.trimDeltaJson(bad), bad);
    });

    test('returns input unchanged when JSON is valid but not a list', () {
      const notList = '"just a string"';
      expect(QuillTextUtils.trimDeltaJson(notList), notList);
    });

    test('no change when last insert has no trailing newline', () {
      final input = deltaJson([
        {'insert': 'Hello world'},
      ]);
      final result = QuillTextUtils.trimDeltaJson(input)!;
      expect(jsonDecode(result), jsonDecode(input));
    });

    test('replaces multiple trailing newlines with a single one', () {
      final input = deltaJson([
        {'insert': 'Hello'},
        {'insert': '\n\n\n'}, // <- should become '\n'
      ]);

      final result = QuillTextUtils.trimDeltaJson(input)!;
      final decoded = (jsonDecode(result) as List).cast<Map<String, dynamic>>();

      expect(decoded.last['insert'], '\n');
      // Ensure earlier ops untouched
      expect(decoded.first['insert'], 'Hello');
    });

    test('keeps attributes when trimming trailing newlines', () {
      final input = deltaJson([
        {'insert': 'Bio text'},
        {
          'insert': '\n\n',
          'attributes': {'align': 'center'},
        },
      ]);

      final result = QuillTextUtils.trimDeltaJson(input)!;
      final decoded = (jsonDecode(result) as List).cast<Map<String, dynamic>>();
      expect(decoded.last['insert'], '\n');
      expect(decoded.last['attributes'], {'align': 'center'});
    });

    test('leaves JSON unchanged when the last op is an embed', () {
      final input = deltaJson([
        {'insert': 'Hello\n\n'},
        {
          'insert': {'image': 'https://example.com/x.png'},
        },
      ]);
      final result = QuillTextUtils.trimDeltaJson(input)!;
      expect(jsonDecode(result), jsonDecode(input));
    });

    test('returns same JSON when no trailing newlines present', () {
      final input = deltaJson([
        {'insert': 'Hello\n'},
      ]);
      final result = QuillTextUtils.trimDeltaJson(input);
      expect(result, input);
    });
  });

  group('trimBioDeltaJson', () {
    // Helper to encode ops into a delta JSON string.
    String deltaJson(List<Map<String, dynamic>> ops) => jsonEncode(ops);

    parameterizedGroup('returns null when content is empty or just whitespace', [
      (input: null, desc: 'null'),
      (input: '', desc: 'empty string'),
      // ignore: use_raw_strings
      (input: '[{"insert":"\\n\\n\\n"}]', desc: 'only newlines'),
      // ignore: use_raw_strings
      (input: '[{"insert":"   \\n\\n"}]', desc: 'spaces + newlines'),
      // ignore: use_raw_strings
      (input: '[{"insert":"\\n\\n\\n\\n"}]', desc: 'multiple newlines only'),
    ], (t) {
      test('case: ${t.desc}', () {
        expect(QuillTextUtils.trimBioDeltaJson(t.input), isNull);
      });
    });

    test('returns input unchanged when JSON cannot be parsed', () {
      const bad = 'not-json';
      expect(QuillTextUtils.trimBioDeltaJson(bad), bad);
    });

    test('returns input unchanged when JSON is valid but not a list', () {
      const notList = '"just a string"';
      expect(QuillTextUtils.trimBioDeltaJson(notList), notList);
    });

    test('collapses multiple consecutive newlines to single newline', () {
      final input = deltaJson([
        {'insert': 'Line 1'},
        {'insert': '\n\n\n'},
        {'insert': 'Line 2\n'},
      ]);

      final result = QuillTextUtils.trimBioDeltaJson(input)!;
      final decoded = (jsonDecode(result) as List).cast<Map<String, dynamic>>();
      final doc = Document.fromJson(decoded);
      final plainText = doc.toPlainText();

      expect(plainText, contains('Line 1\nLine 2'));
      // Should not contain multiple consecutive newlines
      expect(plainText, isNot(contains('\n\n')));
    });

    test('collapses newline-space-newline to single newline', () {
      final input = deltaJson([
        {'insert': 'Line 1'},
        {'insert': '\n \n'},
        {'insert': 'Line 2\n'},
      ]);

      final result = QuillTextUtils.trimBioDeltaJson(input)!;
      final decoded = (jsonDecode(result) as List).cast<Map<String, dynamic>>();
      final doc = Document.fromJson(decoded);
      final plainText = doc.toPlainText();

      expect(plainText, contains('Line 1\nLine 2'));
      // Should not contain multiple consecutive newlines
      expect(plainText, isNot(contains('\n\n')));
      // Should not contain newline-space-newline pattern
      expect(plainText, isNot(contains('\n \n')));
    });

    test('collapses multiple consecutive whitespace-only lines', () {
      final input = deltaJson([
        {'insert': 'Line 1'},
        {'insert': '\n  \n        \n'},
        {'insert': 'Line 2\n'},
      ]);

      final result = QuillTextUtils.trimBioDeltaJson(input)!;
      final decoded = (jsonDecode(result) as List).cast<Map<String, dynamic>>();
      final doc = Document.fromJson(decoded);
      final plainText = doc.toPlainText();

      expect(plainText, contains('Line 1\nLine 2'));
      // Should not contain multiple consecutive newlines
      expect(plainText, isNot(contains('\n\n')));
      // Should not contain whitespace-only line patterns
      expect(plainText, isNot(contains('\n  \n')));
      expect(plainText, isNot(contains('\n        \n')));
    });

    test('removes leading newlines', () {
      final input = deltaJson([
        {'insert': '\n\n\n'},
        {'insert': 'Text content\n'},
      ]);

      final result = QuillTextUtils.trimBioDeltaJson(input)!;
      final decoded = (jsonDecode(result) as List).cast<Map<String, dynamic>>();
      final doc = Document.fromJson(decoded);
      final plainText = doc.toPlainText();

      expect(plainText, startsWith('Text content'));
      expect(plainText, isNot(startsWith('\n')));
    });

    test('removes trailing newlines', () {
      final input = deltaJson([
        {'insert': 'Text content'},
        {'insert': '\n\n\n'},
      ]);

      final result = QuillTextUtils.trimBioDeltaJson(input)!;
      final decoded = (jsonDecode(result) as List).cast<Map<String, dynamic>>();
      final doc = Document.fromJson(decoded);
      final plainText = doc.toPlainText();

      // Should end with single newline (Quill format requirement)
      expect(plainText, endsWith('\n'));
      // Should not contain multiple trailing newlines before the final one
      final withoutFinalNewline = plainText.substring(0, plainText.length - 1);
      expect(withoutFinalNewline, isNot(endsWith('\n')));
    });

    test('removes consecutive newlines in multiple deltas with a single one', () {
      final input = deltaJson([
        {'insert': 'Hello\n'},
        {'insert': '\n\n\n'},
        {'insert': 'World\n'},
      ]);

      final result = QuillTextUtils.trimBioDeltaJson(input)!;
      final decoded = (jsonDecode(result) as List).cast<Map<String, dynamic>>();

      expect(decoded.first['insert'], 'Hello\nWorld\n');
      // Ensure earlier ops untouched
      expect(decoded.length, 1);
    });

    test('preserves mention attributes', () {
      const mentionValue =
          'nostr:nprofile1qqsw5lnjgw2upfuavsatwj2e70cajcwwsk66j7a3ewcamuadk3ca7mcv3crs0';
      final input = deltaJson([
        {'insert': 'Mention '},
        {
          'insert': '@ice',
          'attributes': {'mention': mentionValue},
        },
        {'insert': '  \n'},
      ]);

      final result = QuillTextUtils.trimBioDeltaJson(input)!;
      final decoded = (jsonDecode(result) as List).cast<Map<String, dynamic>>();

      // Find the operation with mention attribute
      final mentionOp = decoded.firstWhere(
        (op) {
          final attributes = op['attributes'] as Map<String, dynamic>?;
          return attributes != null && attributes['mention'] != null;
        },
        orElse: () => <String, dynamic>{},
      );

      expect(mentionOp, isNotEmpty, reason: 'Mention attribute should be preserved');
      final attributes = mentionOp['attributes'] as Map<String, dynamic>?;
      expect(attributes?['mention'], mentionValue);
      final insert = mentionOp['insert'] as String?;
      expect(insert, contains('@ice'));
    });

    test('preserves mention attributes with multiple newlines', () {
      const mentionValue =
          'nostr:nprofile1qqsw5lnjgw2upfuavsatwj2e70cajcwwsk66j7a3ewcamuadk3ca7mcv3crs0';
      final input = deltaJson([
        {'insert': 'Mention '},
        {
          'insert': '@ice',
          'attributes': {'mention': mentionValue},
        },
        {'insert': '\n\n\n'},
        {'insert': 'More text'},
      ]);

      final result = QuillTextUtils.trimBioDeltaJson(input)!;
      final decoded = (jsonDecode(result) as List).cast<Map<String, dynamic>>();

      // Find the operation with mention attribute
      final mentionOp = decoded.firstWhere(
        (op) {
          final attributes = op['attributes'] as Map<String, dynamic>?;
          return attributes != null && attributes['mention'] != null;
        },
        orElse: () => <String, dynamic>{},
      );

      expect(mentionOp, isNotEmpty, reason: 'Mention attribute should be preserved');
      final attributes = mentionOp['attributes'] as Map<String, dynamic>?;
      expect(attributes?['mention'], mentionValue);
    });

    test('preserves mention attributes with newline-space-newline', () {
      const mentionValue =
          'nostr:nprofile1qqsw5lnjgw2upfuavsatwj2e70cajcwwsk66j7a3ewcamuadk3ca7mcv3crs0';
      final input = deltaJson([
        {'insert': 'Mention '},
        {
          'insert': '@ice',
          'attributes': {'mention': mentionValue},
        },
        {'insert': '\n \n'},
        {'insert': 'More text\n'},
      ]);

      final result = QuillTextUtils.trimBioDeltaJson(input)!;
      final decoded = (jsonDecode(result) as List).cast<Map<String, dynamic>>();

      // Find the operation with mention attribute
      final mentionOp = decoded.firstWhere(
        (op) {
          final attributes = op['attributes'] as Map<String, dynamic>?;
          return attributes != null && attributes['mention'] != null;
        },
        orElse: () => <String, dynamic>{},
      );

      expect(mentionOp, isNotEmpty, reason: 'Mention attribute should be preserved');
      final attributes = mentionOp['attributes'] as Map<String, dynamic>?;
      expect(attributes?['mention'], mentionValue);

      // Verify the pattern was collapsed
      final doc = Document.fromJson(decoded);
      final plainText = doc.toPlainText();
      expect(plainText, isNot(contains('\n \n')));
    });

    test('preserves link attributes', () {
      final input = deltaJson([
        {'insert': 'Check out '},
        {
          'insert': 'this link',
          'attributes': {'link': 'https://example.com'},
        },
        {'insert': '\n\n'},
      ]);

      final result = QuillTextUtils.trimBioDeltaJson(input)!;
      final decoded = (jsonDecode(result) as List).cast<Map<String, dynamic>>();

      final linkOp = decoded.firstWhere(
        (op) {
          final attributes = op['attributes'] as Map<String, dynamic>?;
          return attributes != null && attributes['link'] != null;
        },
        orElse: () => <String, dynamic>{},
      );

      expect(linkOp, isNotEmpty, reason: 'Link attribute should be preserved');
      final attributes = linkOp['attributes'] as Map<String, dynamic>?;
      expect(attributes?['link'], 'https://example.com');
    });

    test('preserves hashtag attributes', () {
      final input = deltaJson([
        {'insert': 'Check '},
        {
          'insert': '#hashtag',
          'attributes': {'hashtag': 'hashtag'},
        },
        {'insert': '\n\n'},
      ]);

      final result = QuillTextUtils.trimBioDeltaJson(input)!;
      final decoded = (jsonDecode(result) as List).cast<Map<String, dynamic>>();

      final hashtagOp = decoded.firstWhere(
        (op) {
          final attributes = op['attributes'] as Map<String, dynamic>?;
          return attributes != null && attributes['hashtag'] != null;
        },
        orElse: () => <String, dynamic>{},
      );

      expect(hashtagOp, isNotEmpty, reason: 'Hashtag attribute should be preserved');
      final attributes = hashtagOp['attributes'] as Map<String, dynamic>?;
      expect(attributes?['hashtag'], 'hashtag');
    });

    test('preserves multiple attributes in same text', () {
      const mentionValue =
          'nostr:nprofile1qqsw5lnjgw2upfuavsatwj2e70cajcwwsk66j7a3ewcamuadk3ca7mcv3crs0';
      final input = deltaJson([
        {'insert': 'Mention '},
        {
          'insert': '@ice',
          'attributes': {'mention': mentionValue},
        },
        {'insert': ' and '},
        {
          'insert': '#hashtag',
          'attributes': {'hashtag': 'hashtag'},
        },
        {'insert': '\n\n\n'},
      ]);

      final result = QuillTextUtils.trimBioDeltaJson(input)!;
      final decoded = (jsonDecode(result) as List).cast<Map<String, dynamic>>();

      final mentionOp = decoded.firstWhere(
        (op) {
          final attributes = op['attributes'] as Map<String, dynamic>?;
          return attributes != null && attributes['mention'] != null;
        },
        orElse: () => <String, dynamic>{},
      );
      final hashtagOp = decoded.firstWhere(
        (op) {
          final attributes = op['attributes'] as Map<String, dynamic>?;
          return attributes != null && attributes['hashtag'] != null;
        },
        orElse: () => <String, dynamic>{},
      );

      expect(mentionOp, isNotEmpty, reason: 'Mention attribute should be preserved');
      expect(hashtagOp, isNotEmpty, reason: 'Hashtag attribute should be preserved');
    });

    test('handles complex text with mentions and multiple newlines', () {
      const mentionValue =
          'nostr:nprofile1qqsw5lnjgw2upfuavsatwj2e70cajcwwsk66j7a3ewcamuadk3ca7mcv3crs0';
      final input = deltaJson([
        {'insert': '\n\n'},
        {'insert': 'Mention '},
        {
          'insert': '@ice',
          'attributes': {'mention': mentionValue},
        },
        {'insert': '  \n\n\n'},
        {'insert': 'More text\n'},
      ]);

      final result = QuillTextUtils.trimBioDeltaJson(input)!;
      final decoded = (jsonDecode(result) as List).cast<Map<String, dynamic>>();

      // Should preserve mention
      final mentionOp = decoded.firstWhere(
        (op) {
          final attributes = op['attributes'] as Map<String, dynamic>?;
          return attributes != null && attributes['mention'] != null;
        },
        orElse: () => <String, dynamic>{},
      );
      expect(mentionOp, isNotEmpty, reason: 'Mention attribute should be preserved');
      final attributes = mentionOp['attributes'] as Map<String, dynamic>?;
      expect(attributes?['mention'], mentionValue);

      // Should have trimmed newlines
      final doc = Document.fromJson(decoded);
      final plainText = doc.toPlainText();
      expect(plainText, startsWith('Mention'));
      expect(plainText, isNot(contains('\n\n\n')));
    });

    test('preserves text without attributes', () {
      final input = deltaJson([
        {'insert': 'Simple text'},
        {'insert': '\n\n'},
        {'insert': 'More text\n'},
      ]);

      final result = QuillTextUtils.trimBioDeltaJson(input)!;
      final decoded = (jsonDecode(result) as List).cast<Map<String, dynamic>>();
      final doc = Document.fromJson(decoded);
      final plainText = doc.toPlainText();

      expect(plainText, contains('Simple text'));
      expect(plainText, contains('More text'));
      expect(plainText, isNot(contains('\n\n')));
    });

    test('adds trailing newline when missing', () {
      final input = deltaJson([
        {'insert': 'Text without trailing newline'},
      ]);

      final result = QuillTextUtils.trimBioDeltaJson(input)!;
      final decoded = (jsonDecode(result) as List).cast<Map<String, dynamic>>();
      final doc = Document.fromJson(decoded);
      final plainText = doc.toPlainText();

      expect(plainText, endsWith('\n'));
    });

    test('adds newline as separate operation when last operation has attributes', () {
      const mentionValue =
          'nostr:nprofile1qqsw5lnjgw2upfuavsatwj2e70cajcwwsk66j7a3ewcamuadk3ca7mcv3crs0';
      final input = deltaJson([
        {'insert': 'Mention '},
        {
          'insert': '@ice',
          'attributes': {'mention': mentionValue},
        },
      ]);

      final result = QuillTextUtils.trimBioDeltaJson(input)!;
      final decoded = (jsonDecode(result) as List).cast<Map<String, dynamic>>();

      // Last operation should be a separate newline operation without attributes
      final lastOp = decoded.last;
      expect(lastOp['insert'], '\n');
      expect(lastOp['attributes'], isNull);

      // The mention operation should remain unchanged (not have \n appended)
      final mentionOp = decoded.firstWhere(
        (op) {
          final attributes = op['attributes'] as Map<String, dynamic>?;
          return attributes != null && attributes['mention'] != null;
        },
        orElse: () => <String, dynamic>{},
      );
      expect(mentionOp['insert'], '@ice');
      expect(mentionOp['insert'], isNot(endsWith('\n')));

      // Verify the document ends with newline
      final doc = Document.fromJson(decoded);
      final plainText = doc.toPlainText();
      expect(plainText, endsWith('\n'));
    });
  });
}
