// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class TapToSeeHint extends HookWidget {
  const TapToSeeHint({
    required this.child,
    required this.onTap,
    this.onVisibilityChanged,
    super.key,
  });

  final Widget child;
  final VoidCallback onTap;
  final ValueChanged<bool>? onVisibilityChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;
    final showTooltip = useState(false);

    void toggleTooltip() {
      showTooltip.value = !showTooltip.value;
      onVisibilityChanged?.call(showTooltip.value);
    }

    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned.directional(
          textDirection: Directionality.of(context),
          top: 0,
          bottom: 0,
          start: 64.s,
          end: 64.s,
          child: GestureDetector(
            onTap: showTooltip.value ? null : toggleTooltip,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        if (showTooltip.value)
          Positioned.fill(
            child: GestureDetector(
              onTap: toggleTooltip,
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    toggleTooltip();
                    onTap();
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsetsDirectional.only(
                          start: 16.0.s,
                          end: 12.0.s,
                          top: 9.0.s,
                          bottom: 9.0.s,
                        ),
                        decoration: BoxDecoration(
                          color: colors.onPrimaryAccent,
                          borderRadius: BorderRadius.circular(8.0.s),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primaryText.withValues(alpha: 0.2),
                              blurRadius: 8.0.s,
                              offset: Offset(0, 2.0.s),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.i18n.story_see_post,
                              style: textStyles.subtitle3.copyWith(
                                color: colors.primaryText,
                              ),
                            ),
                            SizedBox(width: 4.0.s),
                            Assets.svg.iconArrowRight.icon(
                              size: 16.0.s,
                              color: colors.primaryText,
                            ),
                          ],
                        ),
                      ),
                      CustomPaint(
                        painter: _NotchPainter(color: colors.onPrimaryAccent),
                        size: Size(19.0.s, 7.0.s),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NotchPainter extends CustomPainter {
  const _NotchPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      // Start from top-left
      ..moveTo(0, 0)
      // Draw curve to the notch
      ..cubicTo(
        size.width * 0.11,
        0,
        size.width * 0.28,
        size.height * 0.44,
        size.width * 0.395,
        size.height * 0.76,
      )
      // Draw the central dip
      ..cubicTo(
        size.width * 0.43,
        size.height * 0.87,
        size.width * 0.46,
        size.height * 0.93,
        size.width * 0.5,
        size.height * 0.93,
      )
      ..cubicTo(
        size.width * 0.54,
        size.height * 0.93,
        size.width * 0.57,
        size.height * 0.87,
        size.width * 0.605,
        size.height * 0.76,
      )
      // Draw curve from notch to top-right
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.44,
        size.width * 0.89,
        0,
        size.width,
        0,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
