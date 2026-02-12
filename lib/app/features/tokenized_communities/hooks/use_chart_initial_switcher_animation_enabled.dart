// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

bool useChartInitialSwitcherAnimationEnabled({
  required bool hasLoadedOnce,
}) {
  final enabled = useState(true);

  useEffect(
    () {
      if (!hasLoadedOnce || !enabled.value) return null;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        enabled.value = false;
      });
      return null;
    },
    [hasLoadedOnce, enabled.value],
  );

  return enabled.value;
}
