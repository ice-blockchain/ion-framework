// SPDX-License-Identifier: ice License 1.0

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
}
