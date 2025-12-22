// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Reports the child's laid-out size after each frame when it changes.
///
/// Useful for sliver headers / dynamic layout where you need to know the final
/// rendered size (and react to it) without causing layout-time cycles.
class MeasureSize extends HookWidget {
  const MeasureSize({
    required this.onChange,
    required this.child,
    super.key,
  });

  final ValueChanged<Size> onChange;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final oldSize = useState<Size?>(null);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = context.size;
      if (size == null || oldSize.value == size) return;
      oldSize.value = size;
      onChange(size);
    });

    return child;
  }
}
