// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/scroll_button/scroll_button.dart';

class ScrollToTopButton extends StatelessWidget {
  const ScrollToTopButton({
    required this.scrollController,
    super.key,
  });

  /// Minimum number of comments required to show the scroll-to-top button
  static const int minCommentsThreshold = 5;

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ScrollButton(
      scrollController: scrollController,
      direction: ScrollDirection.up,
      onTap: () {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      },
    );
  }
}
