// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StatusBarColorWrapper extends StatelessWidget {
  const StatusBarColorWrapper.light({required this.child, super.key}) : light = true;

  const StatusBarColorWrapper.dark({required this.child, super.key}) : light = false;

  final Widget child;
  final bool light;

  SystemUiOverlayStyle _style(BuildContext context) => SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: light ? Brightness.light : Brightness.dark,
        statusBarBrightness: light ? Brightness.dark : Brightness.light,
      );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _style(context),
      child: child,
    );
  }
}
