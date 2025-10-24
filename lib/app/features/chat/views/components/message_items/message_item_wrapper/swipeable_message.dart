// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class SwipeableMessage extends HookWidget {
  const SwipeableMessage({
    required this.child,
    required this.onSwipeToReply,
    required this.accentTheme,
    super.key,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onSwipeToReply;
  final bool enabled;
  final bool accentTheme;

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 100),
    );
    final swipeOffset = useState<double>(0);
    final animationStartValue = useRef<double>(0);

    final iconSize = 20.0.s;
    final innerPadding = 8.0.s;
    final outerPadding = 16.0.s;
    final replyIconOffset = iconSize + (2 * innerPadding) + outerPadding;
    final maxSwipeDistance = replyIconOffset + outerPadding;

    // Setup animation listener with proper cleanup
    useEffect(
      () {
        void animationListener() {
          final progress = animationController.value;
          final currentValue = Tween<double>(
            begin: animationStartValue.value,
            end: 0,
          ).transform(Curves.easeOut.transform(progress));
          swipeOffset.value = currentValue;

          // Ensure final value is exactly 0 when animation completes
          if (animationController.status == AnimationStatus.completed) {
            swipeOffset.value = 0;
          }
        }

        void statusListener(AnimationStatus status) {
          if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
            swipeOffset.value = 0;
          }
        }

        animationController
          ..addListener(animationListener)
          ..addStatusListener(statusListener);

        return () {
          animationController
            ..removeListener(animationListener)
            ..removeStatusListener(statusListener);
        };
      },
      [animationController],
    );

    final handleSwipeEnd = useCallback(
      () {
        if (!enabled) {
          return;
        }

        // Store the current swipe value before animation starts
        final currentSwipeValue = swipeOffset.value;

        // Check threshold BEFORE starting animation
        if (currentSwipeValue.abs() >= replyIconOffset) {
          HapticFeedback.lightImpact();
          onSwipeToReply();
        }

        // Now animate back to 0
        animationStartValue.value = currentSwipeValue;
        animationController.forward(from: 0);
      },
      [enabled, swipeOffset, animationController, replyIconOffset, onSwipeToReply],
    );

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (!enabled) {
          return;
        }

        // Only allow left swipe (negative delta)
        if (details.delta.dx < 0) {
          final newOffset = swipeOffset.value + details.delta.dx;
          swipeOffset.value = newOffset.clamp(-maxSwipeDistance, 0.0);
        }
      },
      onHorizontalDragEnd: (_) => handleSwipeEnd(),
      child: Stack(
        children: [
          // Reply icon that appears on the right as user swipes left
          if (swipeOffset.value < 0)
            _ReplyIcon(
              accentTheme: accentTheme,
              swipeOffset: swipeOffset.value,
              maxSwipeDistance: replyIconOffset,
              iconSize: iconSize,
              innerPadding: innerPadding,
              outerPadding: outerPadding,
            ),
          // Message content that slides left
          Transform.translate(
            offset: Offset(swipeOffset.value, 0),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _ReplyIcon extends StatelessWidget {
  const _ReplyIcon({
    required this.accentTheme,
    required this.swipeOffset,
    required this.maxSwipeDistance,
    required this.iconSize,
    required this.innerPadding,
    required this.outerPadding,
  });

  final bool accentTheme;
  final double swipeOffset;
  final double maxSwipeDistance;
  final double iconSize;
  final double innerPadding;
  final double outerPadding;

  double get _iconOffset {
    final offset = -maxSwipeDistance - swipeOffset;
    return offset >= 0 ? 0.0 : offset;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      right: _iconOffset,
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Padding(
          padding: EdgeInsetsDirectional.only(end: outerPadding),
          child: Container(
            padding: EdgeInsets.all(innerPadding),
            decoration: BoxDecoration(
              color: accentTheme
                  ? context.theme.appColors.primaryAccent
                  : context.theme.appColors.secondaryBackground,
              borderRadius: BorderRadius.circular(iconSize / 2),
            ),
            child: Assets.svg.iconChatReply.icon(
              size: iconSize,
              color: accentTheme
                  ? context.theme.appColors.onPrimaryAccent
                  : context.theme.appColors.primaryText,
            ),
          ),
        ),
      ),
    );
  }
}
