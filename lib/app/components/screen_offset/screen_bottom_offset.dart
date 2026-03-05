// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/material.dart';

/// Default bottom padding applied when no system insets are detected.
const kDefaultBottomPadding = 12.0;

/// Widget that accounts for system UI insets (e.g., home indicator on iOS,
/// navigation bar on Android) and adds appropriate bottom padding.
///
/// Logic depends on [includeSystemPadding]:
/// - `true` (screens): Uses [MediaQuery.viewPaddingOf] - includes system UI
///   that doesn't shrink the view (like home indicator). Adds extra 12px on
///   Android for the navigation bar.
/// - `false` (sheets/modals): Uses [MediaQuery.paddingOf] - returns padding
///   that actually shrinks the view (safe area). No extra Android padding.
class ScreenBottomOffset extends StatelessWidget {
  const ScreenBottomOffset({
    super.key,
    this.child,
    this.margin,
    this.includeSystemPadding = true,
  });

  final Widget? child;
  final double? margin;

  /// Controls the padding calculation logic:
  /// - `true` (default): For full-screen pages. Uses viewPaddingOf and adds
  ///   extra 12px on Android for navigation bar.
  /// - `false`: For sheets/modals. Uses paddingOf (safe area) without
  ///   extra Android padding.
  final bool includeSystemPadding;

  @override
  Widget build(BuildContext context) {
    // viewPaddingOf: system UI that doesn't shrink the app's view
    // paddingOf: padding that shrinks the view (safe area)
    final bottomInset = includeSystemPadding
        ? MediaQuery.viewPaddingOf(context).bottom
        : MediaQuery.paddingOf(context).bottom;

    // On Android with includeSystemPadding, add extra padding for nav bar
    final systemPadding = Platform.isAndroid && includeSystemPadding
        ? bottomInset + kDefaultBottomPadding
        : bottomInset;

    // Use provided margin, calculated padding, or default minimum
    final bottomPadding = margin ?? (systemPadding > 0 ? systemPadding : kDefaultBottomPadding);

    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: bottomPadding),
      child: child,
    );
  }
}
