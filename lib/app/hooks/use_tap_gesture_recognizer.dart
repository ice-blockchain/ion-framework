// SPDX-License-Identifier: ice License 1.0

import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

TapGestureRecognizer useTapGestureRecognizer({
  VoidCallback? onTap,
}) {
  final tapGestureRecognizer = useMemoized(TapGestureRecognizer.new);
  // Should be disposed: https://api.flutter.dev/flutter/painting/TextSpan/recognizer.html
  useEffect(() => tapGestureRecognizer.dispose, [tapGestureRecognizer]);
  if (onTap != null) {
    tapGestureRecognizer.onTap = onTap;
  }
  return tapGestureRecognizer;
}

List<TapGestureRecognizer> useTapGestureRecognizers() {
  final recognizers = <TapGestureRecognizer>[];

  useEffect(
    () {
      return () {
        for (final recognizer in recognizers) {
          recognizer.dispose();
        }
      };
    },
    [recognizers],
  );

  return recognizers;
}
