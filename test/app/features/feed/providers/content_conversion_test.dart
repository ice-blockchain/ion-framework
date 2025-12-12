// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/feed/providers/content_conversion.dart';
import 'package:ion/app/features/ion_connect/model/pmo_tag.f.dart';

void main() {
  group('trimEmptyLines', () {
    group('empty and edge cases', () {
      test('returns empty string unchanged', () {
        final result = trimEmptyLines('');
        expect(result.trimmedText, '');
      });

      test('returns empty string for all newlines', () {
        final result = trimEmptyLines('\n\n\n');
        expect(result.trimmedText, '');
      });

      test('returns empty string for single newline', () {
        final result = trimEmptyLines('\n');
        expect(result.trimmedText, '');
      });
    });

    group('leading newlines', () {
      test('removes single leading newline', () {
        final result = trimEmptyLines('\nHello world');
        expect(result.trimmedText, 'Hello world');
      });

      test('removes multiple leading newlines', () {
        final result = trimEmptyLines('\n\n\nHello world');
        expect(result.trimmedText, 'Hello world');
      });

      test('removes leading newlines with text after', () {
        final result = trimEmptyLines('\n\n\nText');
        expect(result.trimmedText, 'Text');
      });
    });

    group('trailing newlines', () {
      test('removes single trailing newline', () {
        final result = trimEmptyLines('Hello world\n');
        expect(result.trimmedText, 'Hello world');
      });

      test('removes multiple trailing newlines', () {
        final result = trimEmptyLines('Hello world\n\n\n');
        expect(result.trimmedText, 'Hello world');
      });

      test('removes trailing newlines with text before', () {
        final result = trimEmptyLines('Text\n\n\n');
        expect(result.trimmedText, 'Text');
      });
    });

    group('leading and trailing newlines', () {
      test('removes both leading and trailing newlines', () {
        final result = trimEmptyLines('\n\nHello world\n\n');
        expect(result.trimmedText, 'Hello world');
      });

      test('removes multiple leading and trailing newlines', () {
        final result = trimEmptyLines('\n\n\nText\n\n\n');
        expect(result.trimmedText, 'Text');
      });
    });

    group('collapsing multiple newlines', () {
      test('preserves single newline between paragraphs', () {
        final result = trimEmptyLines('First\nSecond');
        expect(result.trimmedText, 'First\nSecond');
      });

      test('preserves two consecutive newlines between paragraphs', () {
        final result = trimEmptyLines('First\n\nSecond');
        expect(result.trimmedText, 'First\n\nSecond');
      });

      test('collapses three consecutive newlines to two', () {
        final result = trimEmptyLines('First\n\n\nSecond');
        expect(result.trimmedText, 'First\n\nSecond');
      });

      test('collapses many consecutive newlines to two', () {
        final result = trimEmptyLines('First\n\n\n\n\nSecond');
        expect(result.trimmedText, 'First\n\nSecond');
      });

      test('handles multiple sequences of multiple newlines', () {
        final result = trimEmptyLines('First\n\nSecond\n\n\nThird');
        expect(result.trimmedText, 'First\n\nSecond\n\nThird');
      });
    });

    group('complex scenarios', () {
      test('handles text with leading, trailing, and multiple newlines', () {
        final result = trimEmptyLines('\n\nFirst\n\nSecond\n\n\nThird\n\n');
        expect(result.trimmedText, 'First\n\nSecond\n\nThird');
        expect(result.trimmedText.length, 20);
      });

      test('handles single line text', () {
        final result = trimEmptyLines('Hello world');
        expect(result.trimmedText, 'Hello world');
      });

      test('handles text with only single newlines', () {
        final result = trimEmptyLines('Line1\nLine2\nLine3');
        expect(result.trimmedText, 'Line1\nLine2\nLine3');
        expect(result.trimmedText.length, 17);
      });

      test('handles mixed single and multiple newlines', () {
        final result = trimEmptyLines('Line1\nLine2\n\n\nLine3\nLine4');
        expect(result.trimmedText, 'Line1\nLine2\n\nLine3\nLine4');
      });
    });

    group('position adjustment', () {
      test('adjusts positions correctly for leading newlines', () {
        final result = trimEmptyLines('\n\nHello');
        // Position 0, 1 (leading newlines) -> 0
        expect(result.adjustPosition(0), 0);
        expect(result.adjustPosition(1), 0);
        // Position 2 ('H') -> 0
        expect(result.adjustPosition(2), 0);
        // Position 3 ('e') -> 1
        expect(result.adjustPosition(3), 1);
      });

      test('adjusts positions correctly for trailing newlines', () {
        final result = trimEmptyLines('Hello\n\n');
        // Trailing newlines are removed, so position 5+ maps to end of trimmed text
        final trimmedLength = result.trimmedText.length;
        expect(result.adjustPosition(5), trimmedLength);
        expect(result.adjustPosition(6), trimmedLength);
        expect(result.adjustPosition(7), trimmedLength);
      });

      test('adjusts positions correctly for collapsed newlines', () {
        final result = trimEmptyLines('First\n\n\nSecond');
        // Position 5 (first '\n') -> 5 (kept)
        expect(result.adjustPosition(5), 5);
        // Position 6 (second '\n') -> 6 (kept)
        expect(result.adjustPosition(6), 6);
        // Position 7 (third '\n') -> 6 (collapsed to second)
        expect(result.adjustPosition(7), 6);
        // Position 8 ('S') -> 7
        expect(result.adjustPosition(8), 7);
      });

      test('handles positions before start index', () {
        final result = trimEmptyLines('\n\nText');
        expect(result.adjustPosition(-1), 0);
        expect(result.adjustPosition(0), 0);
        expect(result.adjustPosition(1), 0);
      });

      test('handles positions after end index', () {
        final result = trimEmptyLines('Text\n\n');
        final trimmedLength = result.trimmedText.length;
        expect(result.adjustPosition(4), trimmedLength);
        expect(result.adjustPosition(5), trimmedLength);
        expect(result.adjustPosition(100), trimmedLength);
      });
    });
  });

  group('adjustPmoTagPositions integration', () {
    test('adjusts PMO tag positions after trimming', () {
      // Text: "\n\nHello\n\n\nworld\n\n"
      // After trimming: "Hello\n\nworld" (3 newlines collapse to 2)
      final result = trimEmptyLines('\n\nHello\n\n\nworld\n\n');

      final tags = [
        const PmoTag(start: 2, end: 7, replacement: '**Hello**'), // "Hello"
        const PmoTag(start: 10, end: 15, replacement: '**world**'), // "world"
      ];

      final adjustedTags = adjustPmoTagPositions(tags, result.adjustPosition);

      expect(adjustedTags, hasLength(2));
      expect(adjustedTags[0].start, 0);
      expect(adjustedTags[0].end, 5);
      expect(adjustedTags[1].start, 7);
      expect(adjustedTags[1].end, 12);
    });
  });

  group('trimEmptyLines with allowExtraLinebreaks: false', () {
    group('leading and trailing newlines', () {
      test('removes leading newlines', () {
        final result = trimEmptyLines('\n\n\nHello world', allowExtraLineBreak: false);
        expect(result.trimmedText, 'Hello world');
      });

      test('removes trailing newlines', () {
        final result = trimEmptyLines('Hello world\n\n\n', allowExtraLineBreak: false);
        expect(result.trimmedText, 'Hello world');
      });

      test('removes both leading and trailing newlines', () {
        final result = trimEmptyLines('\n\nHello world\n\n', allowExtraLineBreak: false);
        expect(result.trimmedText, 'Hello world');
      });
    });

    group('collapsing multiple newlines', () {
      test('preserves single newline between paragraphs', () {
        final result = trimEmptyLines('First\nSecond', allowExtraLineBreak: false);
        expect(result.trimmedText, 'First\nSecond');
      });

      test('collapses many consecutive newlines to one', () {
        final result = trimEmptyLines('First\n\n\n\n\nSecond', allowExtraLineBreak: false);
        expect(result.trimmedText, 'First\nSecond');
      });

      test('handles multiple sequences of multiple newlines', () {
        final result = trimEmptyLines('First\n\nSecond\n\n\nThird', allowExtraLineBreak: false);
        expect(result.trimmedText, 'First\nSecond\nThird');
      });
    });

    group('complex scenarios', () {
      test('handles text with leading, trailing, and multiple newlines', () {
        final result =
            trimEmptyLines('\n\nFirst\n\nSecond\n\n\nThird\n\n', allowExtraLineBreak: false);
        expect(result.trimmedText, 'First\nSecond\nThird');
      });

      test('handles single line text', () {
        final result = trimEmptyLines('Hello world', allowExtraLineBreak: false);
        expect(result.trimmedText, 'Hello world');
      });

      test('handles mixed single and multiple newlines', () {
        final result = trimEmptyLines('Line1\nLine2\n\n\nLine3\nLine4', allowExtraLineBreak: false);
        expect(result.trimmedText, 'Line1\nLine2\nLine3\nLine4');
      });
    });
  });

  group('trimLineWhitespaceInDelta', () {
    String deltaToPlainText(Delta delta) {
      final normalizedDelta = Delta();
      var addedNewline = false;
      for (final op in delta.operations) {
        normalizedDelta.push(op);
      }
      if (normalizedDelta.operations.isNotEmpty) {
        final lastOp = normalizedDelta.operations.last;
        if (lastOp.data is String) {
          final text = lastOp.data! as String;
          if (!text.endsWith('\n')) {
            normalizedDelta.operations.removeLast();
            normalizedDelta.insert('$text\n', lastOp.attributes);
            addedNewline = true;
          }
        } else {
          normalizedDelta.insert('\n');
          addedNewline = true;
        }
      } else {
        normalizedDelta.insert('\n');
        addedNewline = true;
      }
      final plainText = Document.fromDelta(normalizedDelta).toPlainText();
      return addedNewline && plainText.endsWith('\n')
          ? plainText.substring(0, plainText.length - 1)
          : plainText;
    }

    test('trims leading whitespace on lines', () {
      final delta = Delta()..insert('test\n        test\ntest');
      final result = trimLineWhitespaceInDelta(delta);
      expect(deltaToPlainText(result), 'test\ntest\ntest');
    });

    test('trims trailing whitespace on lines', () {
      final delta = Delta()..insert('test     \ntest     \ntest');
      final result = trimLineWhitespaceInDelta(delta);
      expect(deltaToPlainText(result), 'test\ntest\ntest');
    });

    test('trims both leading and trailing whitespace on lines', () {
      final delta = Delta()..insert('test\n        test     \ntest');
      final result = trimLineWhitespaceInDelta(delta);
      expect(deltaToPlainText(result), 'test\ntest\ntest');
    });

    test('trims whitespace with empty lines', () {
      final delta = Delta()..insert('test\n\n                 test\n\n        test');
      final result = trimLineWhitespaceInDelta(delta);
      expect(deltaToPlainText(result), 'test\n\ntest\n\ntest');
    });

    test('trims whitespace with multiple empty lines', () {
      final delta = Delta()..insert('test\n\n\n                 test\n\n        test');
      final result = trimLineWhitespaceInDelta(delta);
      expect(deltaToPlainText(result), 'test\n\n\ntest\n\ntest');
    });

    test('preserves content with no whitespace', () {
      final delta = Delta()..insert('test\ntest\ntest');
      final result = trimLineWhitespaceInDelta(delta);
      expect(deltaToPlainText(result), 'test\ntest\ntest');
    });

    test('trims whitespace on single line', () {
      final delta = Delta()..insert('        test     ');
      final result = trimLineWhitespaceInDelta(delta);
      expect(deltaToPlainText(result), 'test');
    });

    test('handles tabs and spaces', () {
      final delta = Delta()..insert('test\n\t\t  test  \t\n\ttest');
      final result = trimLineWhitespaceInDelta(delta);
      expect(deltaToPlainText(result), 'test\ntest\ntest');
    });

    test('preserves attributes', () {
      final delta = Delta()
        ..insert('test', {'bold': true})
        ..insert('\n        ')
        ..insert('test', {'italic': true})
        ..insert('\ntest');
      final result = trimLineWhitespaceInDelta(delta);
      expect(deltaToPlainText(result), 'test\ntest\ntest');
      // Check that attributes are preserved
      final ops = result.operations;
      expect(ops[0].attributes?['bold'], true);
      expect(ops[2].attributes?['italic'], true);
    });

    test('preserves embeds', () {
      final delta = Delta()
        ..insert('test\n')
        ..insert({'image': 'url'})
        ..insert('\n        test');
      final result = trimLineWhitespaceInDelta(delta);
      final plainText = deltaToPlainText(result);
      expect(plainText, contains('test'));
      expect(plainText.length, greaterThan(8));
      expect(result.operations.any((op) => op.data is Map), true);
    });
  });

  group('integration: trimLineWhitespaceInDelta + trimEmptyLines', () {
    String deltaToPlainText(Delta delta) {
      // Ensure delta ends with newline (Quill Document requirement)
      final normalizedDelta = Delta();
      var addedNewline = false;
      for (final op in delta.operations) {
        normalizedDelta.push(op);
      }
      if (normalizedDelta.operations.isNotEmpty) {
        final lastOp = normalizedDelta.operations.last;
        if (lastOp.data is String) {
          final text = lastOp.data! as String;
          if (!text.endsWith('\n')) {
            normalizedDelta.operations.removeLast();
            normalizedDelta.insert('$text\n', lastOp.attributes);
            addedNewline = true;
          }
        } else {
          normalizedDelta.insert('\n');
          addedNewline = true;
        }
      } else {
        normalizedDelta.insert('\n');
        addedNewline = true;
      }
      final plainText = Document.fromDelta(normalizedDelta).toPlainText();
      return addedNewline && plainText.endsWith('\n')
          ? plainText.substring(0, plainText.length - 1)
          : plainText;
    }

    test('trims whitespace and empty lines together', () {
      final delta = Delta()..insert('test\n\n                 test\n\n        test');
      final trimmedDelta = trimLineWhitespaceInDelta(delta);
      final plain = deltaToPlainText(trimmedDelta);
      final result = trimEmptyLines(plain);
      expect(result.trimmedText, 'test\n\ntest\n\ntest');
    });

    test('trims whitespace and collapses multiple empty lines', () {
      final delta = Delta()..insert('test\n\n\n                 test\n\n        test');
      final trimmedDelta = trimLineWhitespaceInDelta(delta);
      final plain = deltaToPlainText(trimmedDelta);
      final result = trimEmptyLines(plain, allowExtraLineBreak: false);
      expect(result.trimmedText, 'test\ntest\ntest');
    });
  });
}
