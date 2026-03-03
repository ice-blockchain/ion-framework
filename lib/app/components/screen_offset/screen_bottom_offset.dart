// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/num.dart';

class ScreenBottomOffset extends StatelessWidget {
  const ScreenBottomOffset({
    super.key,
    this.child,
    this.margin,
  });

  final Widget? child;
  final double? margin;

  @override
  Widget build(BuildContext context) {
    // viewPaddingOf is the physical safe area (notch/indicator)
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final viewPadding = MediaQuery.viewPaddingOf(context).bottom + viewInsets;
    print(
        'viewInsets:$viewInsets, viewPadding:$viewPadding, paddingOf:${MediaQuery.paddingOf(context).bottom}');

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    final bottomPadding = margin ?? (bottomInset > 0 ? bottomInset + 12.0.s : 12.0.s);

    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: bottomPadding),
      child: child,
    );
  }
}
