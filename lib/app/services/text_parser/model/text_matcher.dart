// SPDX-License-Identifier: ice License 1.0

import 'package:ion/generated/tlds_group.dart';

sealed class TextMatcher {
  const TextMatcher();

  String get pattern;
}

class MentionMatcher extends TextMatcher {
  const MentionMatcher();

  @override
  String get pattern => r'@[A-Za-z0-9.]+\b';
}

class HashtagMatcher extends TextMatcher {
  const HashtagMatcher();

  @override
  String get pattern => r'#[^\s.]+';
}

class UrlMatcher extends TextMatcher {
  const UrlMatcher();

  @override
  String get pattern => r'\b(?:'
      // scheme or www with host (fallback allowed)
      '(?:'
      r'(?:[a-z][a-z0-9+\-.]*):\/\/' // scheme://
      r'|www\.' // or www.
      ')'
      r'(?:[^@\s]+@)?' // optional auth
      r'(?:(?:(?!-)[A-Za-z0-9-]+(?<!-)\.)+' // labels with dots
      '$tldGroup'
      '|(?!-)[A-Za-z0-9-]{2,}(?<!-))' // or fallback host (like localhost)
      '|'
      // bare domain with explicit TLD only
      r'(?:[A-Za-z0-9-]+\.)+' // labels with dots
      '$tldGroup'
      ')'
      r'(?::\d{2,5})?' // optional port
      r'(?:\/[^\s!?.,;:]*[A-Za-z0-9\/])?' // optional path
      r'(?:\?[^\s!?.,;:]*[A-Za-z0-9%_=&-])?' // optional query params ending in valid char
      r'\b'; // word boundary
}

class CashtagMatcher extends TextMatcher {
  const CashtagMatcher();

  @override
  String get pattern => r'\$(?=[\w-]*[A-Za-z])\w+(?:-\w+)*\b';
}
