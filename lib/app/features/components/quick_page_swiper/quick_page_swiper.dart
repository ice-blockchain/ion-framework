// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';

class QuickPageSwiper extends StatelessWidget {
  const QuickPageSwiper({
    required this.child,
    required this.pageController,
    this.swipeDuration = const Duration(milliseconds: 100),
    this.swipeThreshold = 100.0,
    this.direction = Axis.vertical,
    super.key,
  });

  final Widget child;
  final PageController pageController;
  final Duration swipeDuration;
  final double swipeThreshold;
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (direction != Axis.vertical) {
          return;
        }
        // “Pull” the scroll position by exactly the finger movement:
        pageController.jumpTo(
          pageController.offset - details.delta.dy,
        );
      },
      onVerticalDragEnd: (details) {
        if (direction != Axis.vertical) {
          return;
        }

        final vy = details.velocity.pixelsPerSecond.dy;
        final page = pageController.page ?? pageController.initialPage.toDouble();

        // Decide which page to go to
        int targetPage;
        if (vy < -swipeThreshold) {
          // fast swipe *up* → next page
          targetPage = page.ceil();
        } else if (vy > swipeThreshold) {
          // fast swipe *down* → previous page
          targetPage = page.floor();
        } else {
          // gentle swipe → whichever page is closest
          targetPage = page.round();
        }

        pageController.animateToPage(
          targetPage,
          duration: swipeDuration,
          curve: Curves.easeOut,
        );
      },
      onHorizontalDragUpdate: (details) {
        if (direction != Axis.horizontal) {
          return;
        }
        // “Pull” the scroll position by exactly the finger movement:
        pageController.jumpTo(
          pageController.offset - details.delta.dx,
        );
      },
      onHorizontalDragEnd: (details) {
        if (direction != Axis.horizontal) {
          return;
        }

        final vx = details.velocity.pixelsPerSecond.dx;
        final page = pageController.page ?? pageController.initialPage.toDouble();

        // Decide which page to go to
        int targetPage;
        if (vx < -swipeThreshold) {
          // fast swipe *left* → next page
          targetPage = page.ceil();
        } else if (vx > swipeThreshold) {
          // fast swipe *right* → previous page
          targetPage = page.floor();
        } else {
          // gentle swipe → whichever page is closest
          targetPage = page.round();
        }

        pageController.animateToPage(
          targetPage,
          duration: swipeDuration,
          curve: Curves.easeOut,
        );
      },
      child: child,
    );
  }
}
