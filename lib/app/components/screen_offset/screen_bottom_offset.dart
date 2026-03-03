// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

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
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final calculatedPadding = Platform.isAndroid ? bottomInset + 12.0.s : bottomInset;

    print('viewInsets:$viewInsets, viewPadding:$bottomInset, calculatedPadding:$calculatedPadding');

    final bottomPadding = margin ?? (calculatedPadding > 0 ? calculatedPadding : 12.0.s);

    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: bottomPadding),
      child: child,
    );
  }
}
