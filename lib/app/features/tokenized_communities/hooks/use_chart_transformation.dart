// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

({
  GlobalKey chartKey,
  TransformationController transformationController,
  ValueNotifier<bool> isPositioned,
}) useChartTransformation({
  required int dataPointCount,
  required double reservedSize,
}) {
  double calculateInitialScale(int dataPointCount) {
    const maxPointsPerScreen = 35;

    if (dataPointCount < maxPointsPerScreen) {
      return 1;
    }

    return dataPointCount / maxPointsPerScreen;
  }

  final chartKey = useMemoized(GlobalKey.new);
  final initialScale = useMemoized(
    () => calculateInitialScale(dataPointCount),
    [dataPointCount],
  );
  final transformationController = useTransformationController(
    initialValue: Matrix4.identity()..scaleByDouble(initialScale, initialScale, 1, 1),
  );
  final isPositioned = useState(false);
  final previousScaleRef = useRef(initialScale);

  useEffect(
    () {
      final oldScale = previousScaleRef.value;
      previousScaleRef.value = initialScale;

      final scaleChangeRatio = oldScale > 0 ? (initialScale - oldScale).abs() / oldScale : 1.0;

      // Hide on initial positioning or significant scale change (>5%),
      // e.g. a timeframe switch, to prevent 1-frame glitch with wrong
      // transform. Small changes from realtime candle additions (~1-3%)
      // reposition silently to avoid flicker.
      if (!isPositioned.value || scaleChangeRatio > 0.05) {
        isPositioned.value = false;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = chartKey.currentContext;
        if (ctx == null) return;
        final box = ctx.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) return;

        final totalWidth = box.size.width;
        final drawableWidth = totalWidth - reservedSize;
        final translateX = -drawableWidth * (initialScale - 1);

        transformationController.value = Matrix4.identity()
          ..translateByDouble(translateX, 0, 0, 1)
          ..scaleByDouble(initialScale, initialScale, 1, 1);

        isPositioned.value = true;
      });
      return null;
    },
    [initialScale, reservedSize],
  );

  return (
    chartKey: chartKey,
    transformationController: transformationController,
    isPositioned: isPositioned,
  );
}
