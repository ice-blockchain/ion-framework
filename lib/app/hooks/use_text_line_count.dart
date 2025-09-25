// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

int useTextLineCount({
  required String text,
  required TextStyle textStyle,
  required double maxWidth,
  required TextScaler scaler,
}) {
  return useMemoized(
    () {
      if (text.isEmpty) return 0;

      final textPainter = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout(maxWidth: maxWidth);

      final lineMetrics = textPainter.computeLineMetrics();
      textPainter.dispose();

      return lineMetrics.length;
    },
    [text, textStyle, maxWidth, scaler],
  );
}
