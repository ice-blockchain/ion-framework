// SPDX-License-Identifier: ice License 1.0

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/num.dart';

double getBottomPadding(BuildContext context, {required double navBarVerticalPadding}) {
  final mqPaddings = MediaQuery.paddingOf(context);
  if (Platform.isIOS) {
    // On iOS we need to get under safe area a bit(8px), because the safe area is bigger than the home indicator itself
    // assuming the is no devices older than iPhone X in use
    return max(0, mqPaddings.bottom - navBarVerticalPadding.s - 8.s);
  } else if (Platform.isAndroid && MediaQuery.systemGestureInsetsOf(context).left > 0) {
    // On Android we need to check for system gesture insets to determine is there is a 2/3 button navigation or home indicator
    // The system nav bar inset may vary so we can just use some average formula

    return mqPaddings.bottom > 12.s ? max(0, (mqPaddings.bottom / 2) + 6.s) : mqPaddings.bottom;
  } else {
    // Default case, just return the bottom padding
    // for all cases when there is no gesture inset (old devices with buttons, etc)
    return mqPaddings.bottom;
  }
}
