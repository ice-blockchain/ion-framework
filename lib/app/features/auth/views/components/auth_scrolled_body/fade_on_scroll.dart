// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class FadeOnScroll extends HookWidget {
  const FadeOnScroll({
    required this.child,
    required this.positionNotifier,
    super.key,
    this.zeroOpacityOffset = 0,
    this.fullOpacityOffset = 100,
  }) : assert(
          zeroOpacityOffset >= 0 && fullOpacityOffset >= 0,
          'Both zeroOpacityOffset and fullOpacityOffset must be positive',
        );

  final Widget child;

  final double zeroOpacityOffset;

  final double fullOpacityOffset;

  final ValueNotifier<double> positionNotifier;

  double _calculateOpacity(double offset) {
    final fadeIn = zeroOpacityOffset < fullOpacityOffset;
    final start = fadeIn ? zeroOpacityOffset : fullOpacityOffset;
    final end = fadeIn ? fullOpacityOffset : zeroOpacityOffset;
    final diff = (offset - start) / (end - start);
    return (fadeIn ? diff : (1 - diff)).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final opacity = useState<double>(_calculateOpacity(positionNotifier.value));

    useEffect(
      () {
        void setOpacity() => opacity.value = _calculateOpacity(positionNotifier.value);
        positionNotifier.addListener(setOpacity);
        return () => positionNotifier.removeListener(setOpacity);
      },
      [],
    );

    return Opacity(
      opacity: opacity.value,
      child: child,
    );
  }
}
