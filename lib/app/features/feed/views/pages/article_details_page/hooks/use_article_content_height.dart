// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// A hook that calculates the height of content by rendering it offscreen.
///
/// Returns a record containing:
/// - `height`: The calculated height (0.0 until measured)
/// - `measurer`: A widget to be placed in an Offstage for measurement
///
/// The [contentBuilder] should return the widget tree to measure.
/// The [contentKey] is used to detect when content changes and re-measure.
(double height, Widget measurer) useContentHeight({
  required Widget Function(GlobalKey key) contentBuilder,
  required Object contentKey,
}) {
  final measurerKey = useMemoized(GlobalKey.new, [contentKey]);
  final height = useState<double>(0);

  useEffect(
    () {
      var isDisposed = false;

      void measure() {
        if (isDisposed) return;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (isDisposed) return;

          final context = measurerKey.currentContext;
          if (context != null) {
            final box = context.findRenderObject() as RenderBox?;
            if (box != null && box.hasSize) {
              height.value = box.size.height;
              return;
            }
          }
          measure();
        });
      }

      measure();

      return () {
        isDisposed = true;
      };
    },
    [measurerKey, contentKey],
  );

  return (height.value, contentBuilder(measurerKey));
}
