// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/gestures.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// A hook that manages the lifecycle of multiple [TapGestureRecognizer] instances.
///
/// This hook automatically disposes all recognizers when they are no longer needed,
/// preventing resource leaks. It's useful for managing recognizers created dynamically
/// in text span building operations.
///
/// Returns a list that can be used to store recognizers created with
/// [useTapGestureRecognizer] for batch management and disposal.
///
/// Example:
/// ```dart
/// final recognizers = useTapGestureRecognizers();
/// final recognizer = useTapGestureRecognizer(onTap: () => handleTap());
/// recognizers.add(recognizer);
/// ```
///
/// Or for building recognizers inline:
/// ```dart
/// final recognizers = useTapGestureRecognizers();
/// final textSpan = replaceString(
///   description,
///   tagRegex('username'),
///   (match, index) {
///     final recognizer = TapGestureRecognizer()
///       ..onTap = () => handleTap();
///     recognizers.add(recognizer);
///     return TextSpan(recognizer: recognizer);
///   },
/// );
/// ```
List<TapGestureRecognizer> useTapGestureRecognizers() {
  final recognizers = useState<List<TapGestureRecognizer>>([]);

  useEffect(
    () {
      return () {
        for (final recognizer in recognizers.value) {
          recognizer.dispose();
        }
      };
    },
    [recognizers.value],
  );

  return recognizers.value;
}
