// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class ScrollToTopButton extends HookWidget {
  const ScrollToTopButton({
    required this.scrollController,
    super.key,
  });

  static final _offsetThreshold = 200.0.s;

  /// Minimum number of comments required to show the scroll-to-top button
  static const int minCommentsThreshold = 5;

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final isVisible = useState(false);

    useEffect(() {
      void listener() {
        isVisible.value = scrollController.offset > _offsetThreshold;
      }

      scrollController.addListener(listener);
      return () => scrollController.removeListener(listener);
    });

    return AnimatedSwitcher(
      duration: 200.milliseconds,
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: isVisible.value
          ? _ScrollButton(
        onTap: () {
          scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        },
      )
          : const SizedBox.shrink(),
    );
  }
}

class _ScrollButton extends StatelessWidget {
  const _ScrollButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.0.s),
        decoration: ShapeDecoration(
          color: context.theme.appColors.tertiaryBackground,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: context.theme.appColors.onTertiaryFill,
            ),
            borderRadius: BorderRadius.circular(20.0.s),
          ),
          shadows: [
            BoxShadow(
              color: context.theme.appColors.shadow.withValues(alpha: 0.12),
              blurRadius: 16.0.s,
              offset: Offset(-2.0.s, -2.0.s),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24.0.s,
              height: 24.0.s,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(),
              child: Center(
                child: Assets.svg.iconArrowUp.icon(
                  size: 24.0.s,
                  color: context.theme.appColors.sharkText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
