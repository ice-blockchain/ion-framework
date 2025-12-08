// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/services/text_parser/model/text_match.f.dart';
import 'package:ion/app/services/text_parser/model/text_matcher.dart';

class TextParser {
  TextParser({
    required this.matchers,
  }) : assert(
          matchers.isNotEmpty,
          'At least one matcher must be specified.',
        ) {
    /// Why groupIndexStart is 2?
    /// 0 - is the match of the pattern
    /// then 1 + index of the pattern in the pattern list
    ///   + total number of groups in prev patterns is match again
    ///   nulls are in between
    /// then groups of this matched pattern one by one
    ///
    /// Example:
    /// ```dart
    /// final reg = RegExp('(a(a))|(bb)');
    /// final matches = reg.allMatches('ff aa bb aa cc');
    /// ```
    /// matches will be:
    /// [aa, aa, a]
    /// [bb, null, null, bb]
    ///
    /// So if we have groups even inside the first matcher,
    /// they will start from index 2.

    var groupIndexStart = 2;
    final patterns = <String>[];

    for (var i = 0; i < matchers.length; i++) {
      final pattern = matchers.elementAt(i).pattern;
      final groupName = '__parser__$i';
      final groupCount = RegExp('$pattern|.*').firstMatch('')?.groupCount ?? 0;

      patterns.add('(?<$groupName>$pattern)');
      _matcherGroupNames.add(groupName);
      _matcherGroupRanges.add(List.generate(groupCount, (i) => i + groupIndexStart));

      groupIndexStart += groupCount + 1;
    }

    _pattern = patterns.join('|');
  }

  /// TextParser with all matchers, that will be used to parse the text.
  factory TextParser.allMatchers() => TextParser(
        matchers: const {
          UrlMatcher(),
          HashtagMatcher(),
          MentionMatcher(),
          CashtagMatcher(),
        },
      );

  // TextParser without url matcher
  factory TextParser.tagsMatchers() => TextParser(
        matchers: const {
          HashtagMatcher(),
          MentionMatcher(),
          CashtagMatcher(),
        },
      );

  final Set<TextMatcher> matchers;

  final List<String> _matcherGroupNames = [];

  final List<List<int>> _matcherGroupRanges = [];

  late String _pattern;

  /// Cached compiled RegExp for better performance.
  /// Recompiling RegExp on every parse is expensive, especially with complex patterns.
  late final RegExp _regExp = RegExp(_pattern);

  List<TextMatch> parse(String text, {bool onlyMatches = false}) {
    final matches = _regExp.allMatches(text);

    final result = <TextMatch>[];
    var offset = 0;

    for (final match in matches) {
      final substring = text.substring(match.start, match.end);

      final matcherIndex =
          _matcherGroupNames.indexWhere((name) => match.namedGroup(name) == substring);

      if (matcherIndex > -1) {
        final matcher = matchers.elementAt(matcherIndex);

        // Apply post-match validation (important for UrlMatcher TLD validation)
        if (!matcher.validate(substring)) {
          // Invalid match - skip it and don't update offset
          // This will cause it to be included in the next plain text segment
          continue;
        }

        // Valid match - add any preceding plain text first
        if (!onlyMatches && match.start > offset) {
          final plainText = text.substring(offset, match.start);
          result.add(TextMatch(plainText, offset: offset));
        }

        // Then add the matched text
        result.add(
          TextMatch(
            substring,
            offset: match.start,
            matcher: matcher,
            matcherIndex: matcherIndex,
            groups: match.groups(_matcherGroupRanges[matcherIndex]),
          ),
        );

        offset = match.end;
      }
    }

    if (!onlyMatches && offset < text.length) {
      final substring = text.substring(offset);
      result.add(TextMatch(substring, offset: offset));
    }

    return result;
  }
}
