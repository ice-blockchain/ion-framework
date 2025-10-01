// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

enum ScrollDirection {
  up,
  down,
}

class ScrollButton extends HookWidget {
  const ScrollButton({
    required this.scrollController,
    required this.direction,
    required this.onTap,
    super.key,
  });

  final ScrollController scrollController;
  final ScrollDirection direction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isVisible = useState(false);
    final threshold = _getDefaultThreshold();
    final icon = _getIcon();
    final color = context.theme.appColors.primaryAccent;

    useEffect(() {
      void listener() {
        isVisible.value = _shouldShowButton(threshold);
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
          ? _ScrollButtonWidget(
              onTap: onTap,
              icon: icon,
              iconColor: color,
            )
          : const SizedBox.shrink(),
    );
  }

  double _getDefaultThreshold() {
    return direction == ScrollDirection.up ? 200.0.s : 16.0.s;
  }

  Widget _getIcon() {
    return direction == ScrollDirection.up
        ? Assets.svg.iconArrowUp.icon(size: 24.0.s)
        : Assets.svg.iconArrowDown.icon(size: 24.0.s);
  }

  bool _shouldShowButton(double threshold) {
    return direction == ScrollDirection.up
        ? scrollController.offset > threshold
        : scrollController.offset > threshold;
  }
}

class _ScrollButtonWidget extends StatelessWidget {
  const _ScrollButtonWidget({
    required this.onTap,
    required this.icon,
    required this.iconColor,
  });

  final VoidCallback onTap;
  final Widget icon;
  final Color iconColor;

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
                child: IconTheme(
                  data: IconThemeData(color: iconColor),
                  child: icon,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
