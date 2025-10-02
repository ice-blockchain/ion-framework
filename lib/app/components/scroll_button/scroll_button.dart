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
    final icon = _getIcon();

    useEffect(() {
      void listener() {
        final newVisibility = scrollController.offset > 16.0.s;
        if (isVisible.value != newVisibility) {
          isVisible.value = newVisibility;
        }
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
              iconColor: context.theme.appColors.primaryAccent,
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _getIcon() {
    return direction == ScrollDirection.up
        ? Assets.svg.iconArrowUp.icon(size: 24.0.s)
        : Assets.svg.iconArrowDown.icon(size: 24.0.s);
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
        child: IconTheme(
          data: IconThemeData(color: iconColor),
          child: icon,
        ),
      ),
    );
  }
}
