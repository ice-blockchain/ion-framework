// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

bool useChartInitialFadeInVisibility({
  required BuildContext context,
  required bool isLoading,
  required bool hasRenderableData,
}) {
  final hasAppeared = useRef(false);
  final isVisible = useState(false);

  useEffect(
    () {
      if (isLoading || !hasRenderableData || hasAppeared.value) return null;

      hasAppeared.value = true;

      // Flip visibility on the next frame so AnimatedOpacity gets a real 0 -> 1 transition.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        isVisible.value = true;
      });

      return null;
    },
    [isLoading, hasRenderableData],
  );

  return isVisible.value;
}
