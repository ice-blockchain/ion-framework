// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:scrolls_to_top/scrolls_to_top.dart';

/// iOS-specific wrapper that enables scroll-to-top functionality when tapping the status bar.
/// This mimics the native iOS behavior where tapping the status bar scrolls the primary
/// scrollable content to the top.
class ScrollToTopWrapper extends StatelessWidget {
  const ScrollToTopWrapper({
    required this.child,
    required this.scrollController,
    super.key,
  });

  final Widget child;
  final ScrollController scrollController;

  Future<void> _onScrollsToTop(ScrollsToTopEvent event) async {
    if (!scrollController.hasClients) return;

    await scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only enable on iOS platform
    if (Theme.of(context).platform != TargetPlatform.iOS) {
      return child;
    }

    return ScrollsToTop(
      onScrollsToTop: _onScrollsToTop,
      child: child,
    );
  }
}
