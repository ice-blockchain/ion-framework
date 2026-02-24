// SPDX-License-Identifier: ice License 1.0

// ignore: file_names
import 'package:flutter/widgets.dart';

RegExp tagRegex(String tag, {bool isSingular = true}) {
  final groupName = '?<$tag>';
  if (isSingular) {
    return RegExp('($groupName\\[:$tag\\])');
  } else {
    return RegExp('\\[\\[:$tag\\]\\]($groupName.*?)\\[\\[\\/:$tag\\]\\]');
  }
}

TextSpan replaceString(
  String input,
  RegExp regex,
  InlineSpan Function(RegExpMatch, int) onMatch,
) {
  final spans = <InlineSpan>[];
  final groupIndices = <String, int>{};
  var lastMatchEnd = 0;

  for (final match in regex.allMatches(input)) {
    if (match.start > lastMatchEnd) {
      spans.add(TextSpan(text: input.substring(lastMatchEnd, match.start)));
    }

    final groupName = match.groupNames.firstWhere(
      (name) => match.namedGroup(name) != null,
      orElse: () => '',
    );

    final index = groupIndices.putIfAbsent(groupName, () => 0);
    groupIndices[groupName] = index + 1;

    spans.add(onMatch(match, index));
    lastMatchEnd = match.end;
  }

  if (lastMatchEnd < input.length) {
    spans.add(TextSpan(text: input.substring(lastMatchEnd)));
  }

  return TextSpan(children: spans);
}

bool isRTL(BuildContext context) {
  return Directionality.of(context) == TextDirection.rtl;
}
