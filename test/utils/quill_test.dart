// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/components/text_editor/utils/quill_text_utils.dart';

import '../test_utils.dart';

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
}
