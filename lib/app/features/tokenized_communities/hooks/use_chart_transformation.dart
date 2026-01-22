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

  useEffect(
    () {
      isPositioned.value = false;
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
