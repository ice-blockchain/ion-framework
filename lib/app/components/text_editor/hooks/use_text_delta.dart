// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:ion/app/services/markdown/quill.dart';

Delta useTextDelta(
  String text,
) {
  final delta = useMemoized(
    () {
      if (text.isEmpty) {
        return Delta()..insert('$text\n');
      }
      try {
        final textDelta = Delta.fromJson(jsonDecode(text) as List<dynamic>);
        final fullDelta = withFullTags(textDelta);

        return fullDelta;
      } on FormatException {
        // Plain-text fallback: wrap the text in a Delta
        return Delta()..insert('$text\n');
      }
    },
    [text],
  );

  return delta;
}
