// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/num.dart';

class SheetBottomOffset extends StatelessWidget {
  const SheetBottomOffset({
    super.key,
    this.child,
    this.margin,
  });

  final Widget? child;
  final double? margin;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomPadding = margin ?? (bottomInset > 0 ? bottomInset : 12.0.s);

    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: bottomPadding),
      child: child,
    );
  }
}
