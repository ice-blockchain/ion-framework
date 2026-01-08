// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';

extension StringExtensions on String {
  static final RegExp emojiOnlyRegExp = RegExp(
    r'^(?:\p{Emoji}|\p{Emoji_Presentation}|\p{Extended_Pictographic})(?!\d)$',
    unicode: true,
  );

  bool get isEmoji {
    if (RegExp(r'^\d+$').hasMatch(this)) return false;
    return emojiOnlyRegExp.hasMatch(this);
  }

  String capitalize() {
    if (isEmpty) return this;
    if (length == 1) return toUpperCase();
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String toTitleCase() {
    if (isEmpty) return this;
    return split('\n').map((line) {
      return line.split(' ').map((word) => word.capitalize()).join(' ');
    }).join('\n');
  }
}

final placeholderRegExp = RegExp('{{(.*?)}}');

/// Replaces placeholders in the format `{{key}}` within the [input] string
/// using corresponding values from the [placeholders] map.
///
/// Example:
/// ```dart
/// final template = 'Hello, {{name}}! Welcome to {{place}}.';
/// final result = replacePlaceholders(template, {
///   'name': 'Alice',
///   'place': 'Wonderland',
/// });
/// print(result); // Hello, Alice! Welcome to Wonderland.
/// ```
///
String replacePlaceholders(String input, Map<String, String> placeholders) {
  return input.replaceAllMapped(placeholderRegExp, (match) {
    final key = match.group(1)?.trim();
    return placeholders[key] ?? match.group(0)!;
  });
}

bool hasPlaceholders(String input) {
  return placeholderRegExp.hasMatch(input);
}

double calculateTextWidth(String text, TextStyle style) {
  final textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final textWidth = textPainter.width;
  textPainter.dispose();
  return textWidth;
}
