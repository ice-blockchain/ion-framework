// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/services/text_parser/model/text_matcher.dart';
import 'package:ion/app/services/text_parser/text_parser.dart';

import '../../test_utils.dart';

void main() {
  group('TextParser', () {
    late TextParser parser;

    setUp(() {
      parser = TextParser.allMatchers();
    });

    test('should parse mentions correctly', () {
      final results = parser.parse('Hello @user1 and @user2');

      expect(results.length, equals(4));
      expect(results[0].text, equals('Hello '));
      expect(results[1].text, equals('@user1'));
      expect(results[1].matcher, isA<MentionMatcher>());
      expect(results[2].text, equals(' and '));
      expect(results[3].text, equals('@user2'));
      expect(results[3].matcher, isA<MentionMatcher>());

      expect(results.length, 4);
    });

    test('should parse mentions with dots correctly', () {
      final results = parser.parse('Hello @bacchus.1 and @bacchus.ice');

      expect(results.length, equals(4));
      expect(results[0].text, equals('Hello '));
      expect(results[1].text, equals('@bacchus.1'));
      expect(results[1].matcher, isA<MentionMatcher>());
      expect(results[2].text, equals(' and '));
      expect(results[3].text, equals('@bacchus.ice'));
      expect(results[3].matcher, isA<MentionMatcher>());

      expect(results.length, 4);
    });

    test('should parse hashtags correctly', () {
      final results = parser.parse('Check out #flutter and #dart');

      expect(results.length, equals(4));
      expect(results[0].text, equals('Check out '));
      expect(results[1].text, equals('#flutter'));
      expect(results[1].matcher, isA<HashtagMatcher>());
      expect(results[2].text, equals(' and '));
      expect(results[3].text, equals('#dart'));
      expect(results[3].matcher, isA<HashtagMatcher>());

      expect(results.length, 4);
    });

    test('should parse URLs correctly', () {
      final results = parser.parse('Visit https://example.com and http://test.org');

      expect(results.length, equals(4));
      expect(results[0].text, equals('Visit '));
      expect(results[1].text, equals('https://example.com'));
      expect(results[1].matcher, isA<UrlMatcher>());
      expect(results[2].text, equals(' and '));
      expect(results[3].text, equals('http://test.org'));
      expect(results[3].matcher, isA<UrlMatcher>());

      expect(results.length, 4);
    });

    test('should not parse as URLs any text with dot', () {
      final results = parser.parse('Some dummy text.To test links.asd test links');

      expect(results.length, equals(1));
      expect(results[0].text, equals('Some dummy text.To test links.asd test links'));
    });

    test('should parse www-prefixed URLs correctly', () {
      final results = parser.parse('Visit www.example.org/page1 for info');

      expect(results.length, equals(3));
      expect(results[0].text, equals('Visit '));
      expect(results[1].text, equals('www.example.org/page1'));
      expect(results[1].matcher, isA<UrlMatcher>());
      expect(results[2].text, equals(' for info'));

      expect(results.length, 3);
    });

    test('should parse URLs with port and path correctly', () {
      final results = parser.parse('Server at http://localhost:8080/path/to');

      expect(results.length, equals(2));
      expect(results[0].text, equals('Server at '));
      expect(results[1].text, equals('http://localhost:8080/path/to'));
      expect(results[1].matcher, isA<UrlMatcher>());

      expect(results.length, 2);
    });

    test('should parse URLs with credentials correctly', () {
      final results = parser.parse('Login at http://user:pass@example.com/files');

      expect(results.length, equals(2));
      expect(results[0].text, equals('Login at '));
      expect(results[1].text, equals('http://user:pass@example.com/files'));
      expect(results[1].matcher, isA<UrlMatcher>());

      expect(results.length, 2);
    });

    test('should parse URLs with query params correctly', () {
      final results = parser.parse('Login at http://pass@example.com/files?q=test');

      expect(results.length, equals(2));
      expect(results[0].text, equals('Login at '));
      expect(results[1].text, equals('http://pass@example.com/files?q=test'));
      expect(results[1].matcher, isA<UrlMatcher>());

      expect(results.length, 2);
    });

    test('should parse URLs with query params correctly', () {
      final results = parser.parse('Visit http://pass@example.com/files?q=test.no questions');

      expect(results.length, equals(3));
      expect(results[0].text, equals('Visit '));
      expect(results[1].text, equals('http://pass@example.com/files?q=test'));
      expect(results[1].matcher, isA<UrlMatcher>());
      expect(results[2].text, equals('.no questions'));

      expect(results.length, 3);
    });

    test('should parse URLs with dots in domain correctly', () {
      final results = parser.parse('Visit https://ion.onelink.me/f1Pi/4yqm2bwx');

      expect(results.length, equals(2));
      expect(results[0].text, equals('Visit '));
      expect(results[1].text, equals('https://ion.onelink.me/f1Pi/4yqm2bwx'));
      expect(results[1].matcher, isA<UrlMatcher>());

      expect(results.length, 2);
    });

    test('should parse mixed content correctly', () {
      final results = parser.parse(
        'Hey @john, check #trending at https://example.com!',
      );

      expect(results.length, equals(7));
      expect(results[0].text, equals('Hey '));
      expect(results[1].text, equals('@john'));
      expect(results[1].matcher, isA<MentionMatcher>());
      expect(results[2].text, equals(', check '));
      expect(results[3].text, equals('#trending'));
      expect(results[3].matcher, isA<HashtagMatcher>());
      expect(results[4].text, equals(' at '));
      expect(results[5].text, equals('https://example.com'));
      expect(results[5].matcher, isA<UrlMatcher>());
      expect(results[6].text, equals('!'));

      expect(results.length, 7);
    });

    test('should handle empty text correctly', () {
      final results = parser.parse('');
      expect(results, isEmpty);
    });

    test('should parse with onlyMatches=true correctly', () {
      final results = parser.parse(
        'Hey @john, check #trending!',
        onlyMatches: true,
      );

      expect(results.length, equals(2));
      expect(results[0].text, equals('@john'));
      expect(results[0].matcher, isA<MentionMatcher>());
      expect(results[1].text, equals('#trending!'));
      expect(results[1].matcher, isA<HashtagMatcher>());

      expect(results.length, 2);
    });

    test('should preserve correct offsets', () {
      final results = parser.parse('Hi @user #tag');

      expect(results[0].offset, equals(0));
      expect(results[1].offset, equals(3));
      expect(results[2].offset, equals(8));
      expect(results[3].offset, equals(9));

      expect(results.length, 4);
    });

    test('should throw assertion error when no matchers provided', () {
      expect(
        () => TextParser(matchers: const {}),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should parse bare domain with TLD correctly', () {
      final results = parser.parse('Visit ice.io for info');

      expect(results.length, equals(3));
      expect(results[0].text, equals('Visit '));
      expect(results[1].text, equals('ice.io'));
      expect(results[1].matcher, isA<UrlMatcher>());
      expect(results[2].text, equals(' for info'));
    });

    test('should parse bare domain with query params correctly', () {
      final results = parser.parse('Check out ice.io/?ref=testRef for details');

      expect(results.length, equals(3));
      expect(results[0].text, equals('Check out '));
      expect(results[1].text, equals('ice.io/?ref=testRef'));
      expect(results[1].matcher, isA<UrlMatcher>());
      expect(results[2].text, equals(' for details'));
    });

    test('should parse bare domain with path correctly', () {
      final results = parser.parse('Visit ice.io/path/to/page for info');

      expect(results.length, equals(3));
      expect(results[0].text, equals('Visit '));
      expect(results[1].text, equals('ice.io/path/to/page'));
      expect(results[1].matcher, isA<UrlMatcher>());
      expect(results[2].text, equals(' for info'));
    });

    test('should parse bare domain with path and query params correctly', () {
      final results = parser.parse('See ice.io/path?query=value&other=test here');

      expect(results.length, equals(3));
      expect(results[0].text, equals('See '));
      expect(results[1].text, equals('ice.io/path?query=value&other=test'));
      expect(results[1].matcher, isA<UrlMatcher>());
      expect(results[2].text, equals(' here'));
    });

    test('should parse bare domain with .app TLD and query params', () {
      final results = parser.parse('Visit ice.io/?ref=testRef');

      expect(results.length, equals(2));
      expect(results[0].text, equals('Visit '));
      expect(results[1].text, equals('ice.io/?ref=testRef'));
      expect(results[1].matcher, isA<UrlMatcher>());
    });

    test('should parse query params with underscores correctly', () {
      final results = parser.parse('Link: ice.io/?ref=testRef&source=test');

      expect(results.length, equals(2));
      expect(results[0].text, equals('Link: '));
      expect(results[1].text, equals('ice.io/?ref=testRef&source=test'));
      expect(results[1].matcher, isA<UrlMatcher>());
    });

    test('should terminate query params at punctuation', () {
      final results = parser.parse('Check ice.io/?q=test. Next sentence');

      expect(results.length, equals(3));
      expect(results[0].text, equals('Check '));
      expect(results[1].text, equals('ice.io/?q=test'));
      expect(results[1].matcher, isA<UrlMatcher>());
      expect(results[2].text, equals('. Next sentence'));
    });

    test('should parse URLs with colons in path (hash-based file identifiers)', () {
      final results = parser.parse(
        'https://181.41.142.253:4443/files/7a0bc7082bf5be6ef65a4d32a34dab5992849f0ef4fea26b856f421e4a19b90f:6453cd7ec4462521526dac7f520de5a16edc218d4607da2717a917f052b3885c.webp',
      );

      expect(results.length, equals(1));
      expect(
        results[0].text,
        equals(
          'https://181.41.142.253:4443/files/7a0bc7082bf5be6ef65a4d32a34dab5992849f0ef4fea26b856f421e4a19b90f:6453cd7ec4462521526dac7f520de5a16edc218d4607da2717a917f052b3885c.webp',
        ),
      );
      expect(results[0].matcher, isA<UrlMatcher>());
    });

    test('should parse multiple URLs with colons in path', () {
      final results = parser.parse(
        'Post with media https://181.41.142.253:4443/files/hash1:hash2.webp and https://example.com/files/abc:def.mp4',
      );

      expect(results.length, equals(4));
      expect(results[0].text, equals('Post with media '));
      expect(
        results[1].text,
        equals('https://181.41.142.253:4443/files/hash1:hash2.webp'),
      );
      expect(results[1].matcher, isA<UrlMatcher>());
      expect(results[2].text, equals(' and '));
      expect(results[3].text, equals('https://example.com/files/abc:def.mp4'));
      expect(results[3].matcher, isA<UrlMatcher>());
    });

    test('should not parse valid bare domain with TLD but followed by extra symbols', () {
      final results = parser.parse('Visit ice.ion for info');

      expect(results.length, equals(1));
      expect(results[0].text, equals('Visit ice.ion for info'));
    });

    test('should not include trailing dot in hashtag', () {
      final results = parser.parse('Hi #online+.', onlyMatches: true);

      expect(results.length, equals(1));
      expect(results[0].text, equals('#online+'));
      expect(results[0].matcher, isA<HashtagMatcher>());
    });

    // Parameterized tests for hashtags: exclude trailing dots, keep other punctuation.
    parameterizedGroup('hashtag parsing with trailing punctuation', [
      (input: 'Hi #online+.', expected: '#online+'),
      (input: 'Hi #tag..', expected: '#tag'),
      (input: 'See #tag. Next', expected: '#tag'),
      (input: '#онлайн+', expected: '#онлайн+'),
      (input: '#tag_name.', expected: '#tag_name'),
      (input: '#tag!', expected: '#tag!'),
      (input: '#tag,', expected: '#tag'),
      (input: '#tag,g123!', expected: '#tag'),
      (input: '#tag!g123,', expected: '#tag'),
    ], (t) {
      test('should parse "${t.input}" -> ${t.expected}', () {
        final results = parser.parse(t.input, onlyMatches: true);

        expect(results.length, equals(1));
        expect(results[0].text, equals(t.expected));
        expect(results[0].matcher, isA<HashtagMatcher>());
      });
    });
  });
}
