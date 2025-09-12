// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/extensions/extensions.dart';

({double opacity}) useAnimatedOpacityOnScroll(
  ScrollController scrollController, {
  required double topOffset,
}) {
  final opacityValue = useState<double>(0.0.s);

  useEffect(
    () {
      void listener() {
        opacityValue.value = (scrollController.offset / topOffset).clamp(0.0, 1.0);
      }

      scrollController.addListener(listener);
      return () => scrollController.removeListener(listener);
    },
    [scrollController, topOffset],
  );

  return (opacity: opacityValue.value);
}
