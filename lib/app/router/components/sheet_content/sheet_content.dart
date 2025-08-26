// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/router/components/sheet_content/sheet_drag_handle.dart';
import 'package:ion/app/router/components/sheet_content/sheet_shape.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

class SheetContent extends StatelessWidget {
  const SheetContent({
    required this.body,
    super.key,
    this.bottomPadding,
    this.topPadding,
    this.backgroundColor,
    this.bottomBar,
  });

  final Widget body;

  final double? topPadding;

  final double? bottomPadding;

  final Color? backgroundColor;

  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    return SheetContentScaffold(
      backgroundColor: Colors.transparent,
      topBar: SheetDragHandle(topPadding: (topPadding ?? 0) + MediaQuery.paddingOf(context).top),
      extendBodyBehindBottomBar: true,
      bottomBar: bottomBar ?? const SizedBox.shrink(),
      body: SheetShape(
        backgroundColor: backgroundColor,
        bottomPadding: bottomPadding ?? MediaQuery.paddingOf(context).bottom,
        child: body,
      ),
    );
  }
}
