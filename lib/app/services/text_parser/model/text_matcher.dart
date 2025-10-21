// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/utils/tlds_set.dart';

sealed class TextMatcher {
  const TextMatcher();

  String get pattern;

  /// Optional post-match validation for complex matchers.
  /// Returns true if the match is valid, false otherwise.
  bool validate(String match) => true;
}

class MentionMatcher extends TextMatcher {
  const MentionMatcher();

  @override
  String get pattern => r'@[A-Za-z0-9.]+\b';
}

class HashtagMatcher extends TextMatcher {
  const HashtagMatcher();

  @override
  String get pattern => r'#[A-Za-z0-9_\u0400-\u04FF]+(?:[!+](?![A-Za-z0-9_\u0400-\u04FF]))?';
}

class UrlMatcher extends TextMatcher {
  const UrlMatcher();

  /// Optimized pattern that captures URL-like strings with looser TLD matching.
  /// Final TLD validation is done via O(1) HashSet lookup in validate() for better performance.
  /// if you want to match only URLs with a valid TLD, use the pattern from the validate() method.
  @override
  String get pattern => '(?:'
      // URLs with scheme (http://, https://, ftp://, etc.)
      r'\b(?:'
      r'(?:[a-z][a-z0-9+\-.]*):\/\/' // scheme://
      r'(?:[^@\s]+@)?' // optional auth
      r'(?:[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*|localhost)' // host or localhost
      r'(?::\d{2,5})?' // optional port
      r'(?:\/[^\s!?.,;:]*[A-Za-z0-9\/])?' // optional path
      r'(?:\?[^\s!?.,;:]*[A-Za-z0-9%_=&-])?' // optional query params
      r'\b' // word boundary
      ')'
      '|'
      // www-prefixed URLs without scheme
      r'\b(?:'
      r'www\.' // www.
      r'(?:[A-Za-z0-9-]+\.)*[A-Za-z0-9-]+' // domain parts
      r'(?::\d{2,5})?' // optional port
      r'(?:\/[^\s!?.,;:]*[A-Za-z0-9\/])?' // optional path
      r'(?:\?[^\s!?.,;:]*[A-Za-z0-9%_=&-])?' // optional query params
      r'\b' // word boundary
      ')'
      '|'
      // bare domain - must be all lowercase, with valid TLD-like structure
      // This is intentionally loose; real validation happens in validate()
      '(?:'
      '(?<![A-Za-z])' // not preceded by a letter (prevents matching mid-word like "text.To")
      r'[a-z0-9]+(?:[a-z0-9-]*[a-z0-9])?\.(?:[a-z0-9]+(?:[a-z0-9-]*[a-z0-9])?\.)*[a-z]{2,}' // domain.tld
      r'(?::\d{2,5})?' // optional port
      r'(?:\/[^\s!?.,;:]*[A-Za-z0-9\/])?' // optional path
      r'(?:\?[^\s!?.,;:]*[A-Za-z0-9%_=&-])?' // optional query params
      '(?![A-Za-z0-9-])' // not followed by alphanumeric or dash (acts as boundary)
      ')'
      ')';

  /// Validates that the URL has a valid TLD using O(1) HashSet lookup.
  /// This prevents false positives from the looser regex pattern.
  @override
  bool validate(String match) {
    try {
      // Handle special cases
      if (match.startsWith('http://localhost') || match.startsWith('https://localhost')) {
        return true; // localhost is valid
      }

      // Extract the TLD from the URL
      final uri = Uri.tryParse(match.contains('://') ? match : 'https://$match');
      if (uri == null || uri.host.isEmpty) return false;

      final parts = uri.host.split('.');
      if (parts.length < 2) return false;

      final tld = parts.last.toLowerCase();
      return isValidTld(tld);
    } catch (_) {
      return false;
    }
  }
}

class CashtagMatcher extends TextMatcher {
  const CashtagMatcher();

  @override
  String get pattern => r'\$(?=[\w-]*[A-Za-z])\w+(?:-\w+)*\b';
}
